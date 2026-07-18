{ config, lib, pkgs, ... }:

let
  # Build one llama.cpp binary with CUDA for the RTX 5090 and Vulkan for the
  # optional Radeon 780M experiment. CPU MoE work is compiled specifically for
  # the UM790's Zen 4 CPU rather than using nixpkgs' portable CPU variants.
  llamaCpp =
    (pkgs.llama-cpp.override {
      cudaSupport = true;
      vulkanSupport = true;
      blasSupport = true;
      cpuArchDynamicDispatch = false;
    }).overrideAttrs
      (old: {
        cmakeFlags = old.cmakeFlags ++ [ "-DGGML_NATIVE=ON" ];
        preConfigure = ''
          export NIX_ENFORCE_NO_NATIVE=0
          ${old.preConfigure}
        '';
      });

  modelPath = "/var/lib/llm/models/qwen36-27b/Qwen3.6-27B-Q6_K.gguf";

  llamaSwapConfig = pkgs.writeText "llama-swap.yaml" ''
    healthCheckTimeout: 300
    globalTTL: 86400
    startPort: 5800
    models:
      qwen-root:
        ttl: 86400
        concurrencyLimit: 1
        cmd: >-
          ${llamaCpp}/bin/llama-server
          --port ''${PORT}
          --model ${modelPath}
          --alias qwen-root
          --n-gpu-layers 999
          --parallel 1
          --ctx-size 131072
          --flash-attn on
          --cache-type-k q8_0
          --cache-type-v q8_0
          --spec-type draft-mtp
          --spec-draft-n-max 2
          --slot-save-path /dev/shm/llm-slots
          --cache-reuse 256
          --jinja
          --temp 1.0
          --top-p 0.95
          --top-k 20
          --min-p 0.0
          --presence-penalty 1.5
      qwen-leaf:
        ttl: 86400
        concurrencyLimit: 4
        filters:
          setParams:
            chat_template_kwargs:
              enable_thinking: false
              preserve_thinking: true
        cmd: >-
          ${llamaCpp}/bin/llama-server
          --port ''${PORT}
          --model ${modelPath}
          --alias qwen-leaf
          --n-gpu-layers 999
          --parallel 4
          --ctx-size 131072
          --flash-attn on
          --cache-type-k q8_0
          --cache-type-v q8_0
          --spec-type draft-mtp
          --spec-draft-n-max 2
          --jinja
          --temp 0.7
          --top-p 0.8
          --top-k 20
          --min-p 0.0
    routing:
      router:
        use: group
        settings:
          groups:
            qwen-profiles:
              swap: true
              exclusive: true
              members:
                - qwen-root
                - qwen-leaf
  '';
in
lib.mkIf (config.networking.hostName == "Lukes-Um790") {
  environment.systemPackages = [
    llamaCpp
    pkgs.llama-swap
  ];

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
    "d /dev/shm/llm-slots 0750 llm llm -"
  ];

  systemd.services.llama-swap = {
    description = "llama-swap OpenAI-compatible model profile proxy";
    wantedBy = [ "multi-user.target" ];
    wants = [ "egpu-pci-rescan.service" ];
    after = [
      "network.target"
      "egpu-pci-rescan.service"
      "nvidia-persistenced.service"
    ];

    serviceConfig = {
      Type = "simple";
      User = "llm";
      Group = "llm";
      WorkingDirectory = "/var/lib/llm";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /dev/shm/llm-slots";
      ExecStart = "${pkgs.llama-swap}/bin/llama-swap -config ${llamaSwapConfig} -listen 127.0.0.1:8080";
      Restart = "on-failure";
      RestartSec = 10;
      TimeoutStopSec = 120;
    };
  };
}
