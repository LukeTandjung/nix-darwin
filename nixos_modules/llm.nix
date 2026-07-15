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
in
lib.mkIf (config.networking.hostName == "Lukes-Um790") {
  environment.systemPackages = [ llamaCpp ];
}
