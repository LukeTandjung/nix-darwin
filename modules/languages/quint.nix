flake@{ ... }:
let
  recipe =
    { lib, buildNpmPackage, makeWrapper, nodejs, temurin-jre-bin-17 }:
    buildNpmPackage {
      pname = "quint-toolchain";
      version = "0.32.0";

      src = ./quint-toolchain;
      npmDepsHash = "sha256-25VvGbrSupR+OXQe7k8pfdrkiPIQeuApFexaaKxI32E=";
      npmFlags = [ "--legacy-peer-deps" ];
      dontNpmBuild = true;
      nativeBuildInputs = [ makeWrapper ];

      installPhase = ''
        runHook preInstall

        mkdir -p $out/lib/quint-toolchain $out/bin
        cp -r node_modules $out/lib/quint-toolchain/
        cp ${./quint-toolchain/d2-render.mjs} $out/lib/quint-toolchain/d2-render.mjs

        makeWrapper ${nodejs}/bin/node $out/bin/quint \
          --add-flags "$out/lib/quint-toolchain/node_modules/@informalsystems/quint/dist/src/cli.js" \
          --prefix PATH : ${lib.makeBinPath [ temurin-jre-bin-17 ]}
        makeWrapper ${nodejs}/bin/node $out/bin/d2-render \
          --add-flags "$out/lib/quint-toolchain/d2-render.mjs"

        runHook postInstall
      '';

      doInstallCheck = true;
      installCheckPhase = ''
        $out/bin/quint --version
        echo 'x -> y' | $out/bin/d2-render | grep -q '<svg'
        PATH=${lib.makeBinPath [ temurin-jre-bin-17 ]}:$PATH java -version
      '';

      meta = {
        description = "Quint CLI and D2 renderer with Java verification support";
        homepage = "https://quint-lang.org";
        license = with lib.licenses; [
          asl20
          mpl20
        ];
        platforms = lib.platforms.all;
        mainProgram = "quint";
      };
    };
in
{
  builders.quint = pkgs: pkgs.callPackage recipe { };
  perSystem = { pkgs, ... }: {
    packages.quint = flake.config.builders.quint pkgs;
  };

  # Quint is available independently of any agent harness. Skills teaching agents
  # to use it are owned and installed by modules/agents/shared/skills.
  modules.hjem.quint = { pkgs, ... }: {
    packages = [
      (flake.config.builders.quint pkgs)
      pkgs.temurin-jre-bin-17
    ];
  };
}
