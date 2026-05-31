{ config, lib, pkgs, ... }:

let
  # Upstream workaround stack for the AORUS RTX 5090 AI BOX / Blackwell eGPU
  # Linux hard-lock bug:
  #   https://github.com/NVIDIA/open-gpu-kernel-modules/issues/979
  # Pin the exact revision so the kernel module patchset remains reproducible.
  # Do not replace this with a moving branch without re-testing CUDA, Vulkan,
  # vkcube, and CS2.
  nvidiaDriverInjector = pkgs.fetchFromGitHub {
    owner = "apnex";
    repo = "nvidia-driver-injector";
    rev = "556f8e4f4059d806337f44c9e40714821ac837a4";
    hash = "sha256-MGz+FWU8UC8MPq/Eoyqp8DE62eV0PM3r7aJ1B5kbinE=";
  };

  # Small helper so the patch list below mirrors apnex's patches/manifest order.
  injectorPatch = path: "${nvidiaDriverInjector}/patches/${path}";

  # Use NVIDIA 595.71.05 because the apnex patchset is authored against this
  # exact open-gpu-kernel-modules tag. Stock 580/595 could enumerate the card,
  # but actual GPU work such as CUDA/Vulkan/vkcube hard-locked or rebooted the
  # host. The patches add Thunderbolt-eGPU recovery handling, GPU-lost retry
  # paths, eGPU detection, AER visibility, and diagnostic close-path telemetry.
  patchedNvidiaPackage = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "595.71.05";
    sha256_64bit = "sha256-NiA7iWC35JyKQva6H1hjzeNKBek9KyS3mK8G3YRva4I=";
    openSha256 = "sha256-Lfz71QWKM6x/jD2B22SWpUi7/og30HRlXg1kL3EWzEw=";
    settingsSha256 = "sha256-mXnf3jyvznfB3OfKd657rxv0rYHQb/dX/Riw/+N9EKU=";
    persistencedSha256 = "sha256-Z/6IvEEa/XfZ5F5qoSIPvXJLGtscYVqjFxHZaN/M2Ts=";

    # Patch summary:
    # - C1: make the module version come from version.mk.
    # - C2: unmask AER Internal Error so the kernel can surface/recover errors.
    # - C3/C5: avoid turning transient PCIe/MMIO failures into immediate host
    #   death; mark GPU-lost paths more safely.
    # - C4/A1/A3: register PCIe error handlers and add the TB eGPU recovery
    #   state machine.
    # - E1: support force-marking this card as an external GPU.
    # - A2/A4/A5: watchdog/telemetry/version stamp used by the workaround.
    patchesOpen = map injectorPatch [
      "base/C1-kbuild-version-mk.patch"
      "base/C2-aer-internal-unmask.patch"
      "base/C3-gpu-lost-retry.patch"
      "base/C4-err-handlers-scaffold.patch"
      "base/E1-egpu-detection.patch"
      "base/C5-crash-safety.patch"
      "addon/A1-pcie-primitives.patch"
      "addon/A2-bus-loss-watchdog.patch"
      "addon/A3-recovery.patch"
      "addon/A4-close-path-telemetry.patch"
      "addon/A5-version-and-toggles.patch"
    ];
  };

  # The A5 patch changes `modinfo nvidia` from 595.71.05 to
  # 595.71.05-aorus.17. NVIDIA's GSP firmware loader includes that module
  # version in the firmware path, so without this alias the driver asks for:
  #   nvidia/595.71.05-aorus.17/gsp_ga10x.bin
  # while the stock Nix package only provides:
  #   nvidia/595.71.05/gsp_ga10x.bin
  # The blobs themselves are unchanged, so copy them into the patched path.
  patchedNvidiaFirmware = pkgs.runCommand "nvidia-aorus-gsp-firmware" { } ''
    mkdir -p $out/lib/firmware/nvidia/595.71.05-aorus.17
    cp ${patchedNvidiaPackage.firmware}/lib/firmware/nvidia/595.71.05/gsp_ga10x.bin \
      $out/lib/firmware/nvidia/595.71.05-aorus.17/gsp_ga10x.bin
    cp ${patchedNvidiaPackage.firmware}/lib/firmware/nvidia/595.71.05/gsp_tu10x.bin \
      $out/lib/firmware/nvidia/595.71.05-aorus.17/gsp_tu10x.bin
  '';

  # Thunderbolt bridge stabilization. Before this, CUDA worked after patching,
  # but real Vulkan rendering (`vkcube`) eventually produced MMIO-dead / Xid 154
  # and rebooted the host. The apnex stack found that capping the parent bridge
  # to PCIe Gen3 and disabling hardware-autonomous speed changes prevents the TB
  # tunnel from retraining under load. On USB4/TB4 the real tunnel bandwidth is
  # already the bottleneck, so Gen3 x4 is an acceptable stability tradeoff.
  egpuBridgeLinkCap = pkgs.writeShellScript "egpu-bridge-link-cap" ''
    set -euo pipefail

    target_speed="''${CAP_TARGET_SPEED:-3}"
    gpu_bdf=""

    # Find the RTX 5090 PCI function. Device 10de:2b85 is GB202 / RTX 5090.
    for device_path in /sys/bus/pci/devices/*; do
      if [[ -r "$device_path/vendor" && -r "$device_path/device" ]] \
        && [[ "$(<"$device_path/vendor")" == "0x10de" ]] \
        && [[ "$(<"$device_path/device")" == "0x2b85" ]]; then
        gpu_bdf="$(basename "$(readlink -f "$device_path")")"
        break
      fi
    done

    if [[ -z "$gpu_bdf" ]]; then
      echo "egpu-bridge-link-cap: RTX 5090 not present; skipping"
      exit 0
    fi

    # The direct parent bridge is the TB-side PCIe bridge whose Link Control 2
    # register needs the stability tweak.
    bridge_bdf="$(basename "$(dirname "$(readlink -f "/sys/bus/pci/devices/$gpu_bdf")")")"

    # Only touch Thunderbolt/USB4 paths. This avoids degrading/altering a normal
    # internal PCIe GPU if the config is ever reused on a different host.
    thunderbolt_path=0
    current="/sys/bus/pci/devices/$gpu_bdf"
    for _ in $(seq 1 10); do
      parent="$(dirname "$(readlink -f "$current")")"
      parent_bdf="$(basename "$parent")"
      if [[ ! "$parent_bdf" =~ ^[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\. ]]; then
        break
      fi
      if ${pkgs.pciutils}/bin/lspci -s "$parent_bdf" | grep -qiE 'Thunderbolt|USB4'; then
        thunderbolt_path=1
        break
      fi
      current="$parent"
    done

    if [[ "$thunderbolt_path" != 1 ]]; then
      echo "egpu-bridge-link-cap: $gpu_bdf is not behind Thunderbolt/USB4; skipping"
      exit 0
    fi

    lnkctl2="$(${pkgs.pciutils}/bin/setpci -s "$bridge_bdf" CAP_EXP+0x30.W)"
    old_value=$((16#$lnkctl2))

    # Link Control 2 bit 5 = Hardware Autonomous Speed Disable.
    # Target speed 3 = PCIe Gen3. This is intentionally lower than the 5090's
    # native capability; the USB4/TB4 tunnel is the real limit, and this avoids
    # link speed oscillation that triggered GPU-lost crashes.
    new_value=$((old_value | 0x20))
    if [[ -n "$target_speed" && "$target_speed" != 0 ]]; then
      new_value=$(((new_value & ~0xf) | (target_speed & 0xf)))
    fi
    new_hex="$(printf '%04x' "$new_value")"

    echo "egpu-bridge-link-cap: gpu=$gpu_bdf bridge=$bridge_bdf LnkCtl2=0x$lnkctl2 -> 0x$new_hex target=Gen$target_speed hw-auto-speed-disable=1"

    if [[ "$lnkctl2" != "$new_hex" ]]; then
      ${pkgs.pciutils}/bin/setpci -s "$bridge_bdf" CAP_EXP+0x30.W="$new_hex"

      # Trigger a link retrain so the new Target Link Speed takes effect before
      # the NVIDIA module initializes GSP firmware.
      lnkctl="$(${pkgs.pciutils}/bin/setpci -s "$bridge_bdf" CAP_EXP+0x10.W)"
      retrain_value=$(((16#$lnkctl) | 0x20))
      retrain_hex="$(printf '%04x' "$retrain_value")"
      ${pkgs.pciutils}/bin/setpci -s "$bridge_bdf" CAP_EXP+0x10.W="$retrain_hex"
      echo "egpu-bridge-link-cap: retrain triggered on bridge=$bridge_bdf"
    fi
  '';
in
lib.mkIf (config.networking.hostName == "Lukes-Um790") {
  # Keep the AMD iGPU as the display/compositor device and load NVIDIA for the
  # external 5090. Both drivers must be present because GNOME/Wayland stays on
  # AMD while CUDA/Vulkan workloads can explicitly select NVIDIA.
  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];

  hardware = {
    # Install the GSP firmware alias required by the patched aorus module
    # version. Without this, nvidia-smi reports "No devices were found" even
    # though lspci shows the GPU bound to nvidia.
    firmware = [ patchedNvidiaFirmware ];

    graphics = {
      enable = true;
      # Steam/Proton still needs 32-bit GL/Vulkan userspace libraries.
      enable32Bit = true;
    };

    nvidia = {
      # Keep nvidia-drm/KMS off. The AMD iGPU owns the display, and the patched
      # aorus module produced a nvidia-drm/nvidia-modeset version mismatch when
      # DRM was enabled. CUDA and explicit NVIDIA Vulkan ICD selection do not
      # require NVIDIA KMS.
      modesetting.enable = false;

      # Blackwell requires NVIDIA's open kernel modules, and the apnex fixes are
      # patches against the open module tree.
      open = true;

      nvidiaSettings = true;

      # Keep the GPU initialized/warm. Repeated open/close cycles were part of
      # the failure pattern in the upstream investigation, so persistenced helps
      # avoid unnecessary teardown/re-init churn.
      nvidiaPersistenced = true;

      # Stock drivers could enumerate the card but crashed/rebooted under real
      # GPU work. Use the patched package defined above instead.
      package = patchedNvidiaPackage;

      # Disable NVIDIA runtime power management. D3cold/D0 transitions through
      # the USB4/TB bridge are a known trigger for eGPU instability.
      powerManagement.enable = false;
      powerManagement.finegrained = false;

      prime = {
        # NixOS PRIME offload automatically adds nvidia-drm.modeset=1. That is
        # undesirable here because we intentionally keep NVIDIA DRM disabled.
        # Games can select NVIDIA explicitly with VK_ICD_FILENAMES instead.
        offload = {
          enable = false;
          enableOffloadCmd = false;
        };

        # Left documented for future PRIME experiments. PRIME Bus IDs use decimal
        # PCI addresses, not the hex addresses printed by lspci.
        amdgpuBusId = "PCI:196@0:0:0";
        nvidiaBusId = "PCI:102@0:0:0";
      };
    };
  };

  # Authorizes the AORUS enclosure on the Thunderbolt/USB4 security layer. This
  # only makes the enclosure trusted; PCI enumeration still sometimes needs the
  # rescan service below.
  services.hardware.bolt.enable = true;

  boot.extraModprobeConfig = ''
    # Keep the TB-attached Blackwell GPU out of runtime PM paths that are known
    # to hard-lock with stock drivers.
    options nvidia NVreg_DynamicPowerManagement=0x00
    options nvidia NVreg_PreserveVideoMemoryAllocations=0
    options nvidia NVreg_EnableS0ixPowerManagement=0

    # Force the driver to treat this as an external GPU. TB4/TB5 bridges are not
    # always recognized by NVIDIA's built-in eGPU detection, which can cause the
    # driver to run internal-GPU power management paths that are unsafe here.
    options nvidia NVreg_RegistryDwords="RmForceExternalGpu=1"

    # Enable the apnex Thunderbolt-eGPU recovery state machine.
    options nvidia NVreg_TbEgpuRecoverEnable=1

    # Prevent early/udev NVIDIA auto-load. The eGPU service applies the TB link
    # cap first, then explicitly loads the patched modules with --ignore-install.
    install nvidia /bin/false
    install nvidia_modeset /bin/false
    install nvidia_uvm /bin/false
    install nvidia_drm /bin/false
  '';

  # Boot sequencing for the eGPU:
  # 1. wait for bolt/udev so the enclosure is authorized,
  # 2. rescan PCI because the GPU appears after the first NVIDIA load attempt,
  # 3. apply the Gen3 + autonomous-speed-disable TB bridge cap before GSP init,
  # 4. explicitly load the patched modules.
  # This ordering is what changed the system from "vkcube reboots the host" to
  # stable CUDA, Vulkan enumeration, vkcube, and CS2.
  systemd.services.egpu-pci-rescan = {
    description = "Rescan PCIe bus for USB4/Thunderbolt eGPU";
    wantedBy = [ "multi-user.target" ];
    after = [
      "bolt.service"
      "systemd-udev-settle.service"
    ];
    before = [ "nvidia-persistenced.service" ];
    wants = [
      "bolt.service"
      "systemd-udev-settle.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "egpu-pci-rescan" ''
        sleep 5
        echo 1 > /sys/bus/pci/rescan
        sleep 1
        CAP_TARGET_SPEED=3 ${egpuBridgeLinkCap}
        sleep 1
        ${pkgs.kmod}/bin/modprobe --ignore-install nvidia || true
        ${pkgs.kmod}/bin/modprobe --ignore-install nvidia_modeset || true
        ${pkgs.kmod}/bin/modprobe --ignore-install nvidia_uvm || true
      '';
    };
  };

  # Start persistenced only after the eGPU rescan/cap/module-load service. If it
  # starts too early, it can trigger the old "No NVIDIA GPU found" path before
  # the Thunderbolt GPU is actually ready.
  systemd.services.nvidia-persistenced = {
    after = [ "egpu-pci-rescan.service" ];
    wants = [ "egpu-pci-rescan.service" ];
  };

  # Keep VA-API/video decode on the AMD iGPU. This prevents browsers/desktop apps
  # from touching the external NVIDIA GPU accidentally; games/compute workloads
  # should opt into NVIDIA explicitly.
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
  };
}
