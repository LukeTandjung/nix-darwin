flake@{ ... }:
let
  recipe =
    { lib, rustPlatform, fetchFromGitHub, pkg-config, openssl }:
    rustPlatform.buildRustPackage rec {
      pname = "zettyp-lsp";
      version = "0.3.0";

      nativeBuildInputs = [ pkg-config ];
      buildInputs = [ openssl ];

      src = fetchFromGitHub {
        owner = "Project-ZetTypst";
        repo = "ZetTypst";
        rev = "8861a4c9a5cd66e34a2445b07dde96997aef2e7d";
        hash = "sha256-m8kOma+BBZRhdqtEA8+jO3JyLDgJmBRC3RTgavtwzYs=";
      };

      cargoLock.lockFile = src + "/Cargo.lock";
      cargoBuildFlags = [ "--package" pname ];
      # Upstream tests download Typst packages, which Nix's sandbox blocks.
      doCheck = false;

      meta = {
        description = "LSP adapter for Typst announcements";
        homepage = "https://github.com/Project-ZetTypst/ZetTypst";
        license = lib.licenses.mit;
        mainProgram = "zettyp-lsp";
      };
    };
in
{
  builders.zettyp-lsp = pkgs: pkgs.callPackage recipe { };
  perSystem = { pkgs, ... }: {
    packages.zettyp-lsp = flake.config.builders.zettyp-lsp pkgs;
  };
}
