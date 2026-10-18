{ ... }:
let
  ninferPackage =
    {
      lib,
      gcc14Stdenv,
      fetchFromGitHub,
      cmake,
      ninja,
      pkg-config,
      cudaPackages_13_1,
      ffmpeg,
      curl,
      makeWrapper,
    }:
    let
      cuda = cudaPackages_13_1;
    in
    gcc14Stdenv.mkDerivation {
      pname = "ninfer";
      version = "0-unstable-2026-10-05";
      src = fetchFromGitHub {
        owner = "Neroued";
        repo = "ninfer";
        rev = "68c54356fd490ab329bd1475d48957f886bb7dd1";
        sha256 = "1ycfaxrsc4ci3niajzxbc61yjcd0riy6z1h53vvspa8j9c0r0mp7";
      };
      nativeBuildInputs = [
        cmake
        ninja
        pkg-config
        cuda.cuda_nvcc
        makeWrapper
      ];
      buildInputs = [
        cuda.cuda_cudart
        cuda.cccl
        cuda.cuda_nvtx
        cuda.libcublas
        ffmpeg
        curl
      ];
      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DCMAKE_CUDA_ARCHITECTURES=120a"
        "-DCMAKE_CUDA_HOST_COMPILER=${gcc14Stdenv.cc}/bin/g++"
        "-DNINFER_BUILD_APPS=ON"
        "-DBUILD_TESTING=OFF"
        "-DNINFER_BUILD_BENCHMARKS=OFF"
      ];
      enableParallelBuilding = true;
      # Upstream has no install target. All frontend resources are in the artifact.
      installPhase = ''
        runHook preInstall
        install -Dm755 apps/ninfer "$out/bin/ninfer"
        install -Dm755 apps/ninfer-serve "$out/bin/ninfer-serve"
        install -Dm755 apps/ninfer-perplexity "$out/bin/ninfer-perplexity"
        install -Dm644 ../LICENSE "$out/share/licenses/ninfer/LICENSE"
        for program in "$out"/bin/*; do
          wrapProgram "$program" --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
        done
        runHook postInstall
      '';
      meta = {
        description = "Pinned single-RTX-5090 inference engine for v3 NInfer artifacts";
        homepage = "https://github.com/Neroued/ninfer";
        license = lib.licenses.asl20;
        platforms = [ "x86_64-linux" ];
        mainProgram = "ninfer";
      };
    };
in
{
  modules.nixos.llm = { config, lib, pkgs, ... }:
    let
      ninfer = pkgs.callPackage ninferPackage { };
      # Exact artifact used by inference_stack's accepted dflash7-nvfp4 run.
      # Keep the weights out of Git and independent of the experiment directory.
      model = pkgs.fetchurl {
        name = "Swift_1_5_qwen3_8_27b_uncensored_nvfp4.ninfer";
        url = "https://huggingface.co/2beng2/Swift-1.5-Qwen3.8-27B-Uncensored-NVFP4-NInfer/resolve/bc5f15343d55337d067756f40dc524ce6508ba1c/Swift_1_5_qwen3_8_27b_uncensored_nvfp4.ninfer";
        sha256 = "3729a8a74358e0c1e9a729778fa3d44edad8375005594c0bc91a3dc95812354b";
      };
    in
    lib.mkIf (config.networking.hostName == "Lukes-Um790") {
      environment.systemPackages = [ ninfer ];

      users.groups.llm = { };
      users.users = {
        llm = {
          isSystemUser = true;
          group = "llm";
          home = "/var/lib/llm";
        };
        luke.extraGroups = [ "llm" ];
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/llm 0750 llm llm -"
        "d /var/lib/llm/models 0750 llm llm -"
      ];

      systemd.services.ninfer = {
        description = "Swift-1.5 NInfer OpenAI-compatible inference server";
        wantedBy = [ "multi-user.target" ];
        wants = [ "nvidia-persistenced.service" ];
        after = [
          "network.target"
          "nvidia-persistenced.service"
        ];
        environment.CUDA_VISIBLE_DEVICES = "0";

        serviceConfig = {
          Type = "simple";
          User = "llm";
          Group = "llm";
          WorkingDirectory = "/var/lib/llm";
          # Host RAM limits do not cap VRAM; the engine's KV budget is explicit below.
          MemoryHigh = "40G";
          MemoryMax = "48G";
          MemorySwapMax = 0;
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          # Keep NVIDIA devices and the host's localhost endpoint accessible.
          PrivateDevices = false;
          PrivateNetwork = false;
          # NVFP4 KV / DFlash2 K7 profile with single-session capacity. CUDA graphs stay enabled;
          # vision stays disabled. Use the artifact's template, not the frozen
          # benchmark template. Prefix reuse is enabled by default; allow 8 GiB
          # of host backing for retained/paused contexts, not active-attention KV offload.
          ExecStart = lib.concatStringsSep " " [
            "${ninfer}/bin/ninfer-serve"
            "${model}"
            "--host 127.0.0.1 --port 8080"
            "--model-id swift-1.5"
            "--max-context 262144 --kv-capacity 262144"
            "--max-concurrency 1 --max-pending-requests 1"
            "--prefill-chunk 1024 --kv-dtype nvfp4"
            "--host-context-mib 8192 --device-state-slots 0"
            "--temperature 1 --top-p 0.95 --top-k 20 --min-p 0"
            "--presence-penalty 1.5 --frequency-penalty 0"
            "--default-max-tokens 32768 --preserve-thinking"
            "--spec dflash2 --draft-tokens 7 --lm-head-draft"
          ];
          Restart = "on-failure";
          RestartSec = 10;
          TimeoutStopSec = 120;
        };
      };
    };
}
