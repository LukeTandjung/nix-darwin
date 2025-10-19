inputs: self: super: {
  nixosSystem' = config: {
    class = "nixos";
    config = super.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { 
        inherit inputs;
        lib = self;
      };
      modules = [ config ];
    };
  };
  
  darwinSystem' = config: {
    class = "darwin";
    config = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { 
        inherit inputs;
        lib = self;
      };
      modules = [ config ];
    };
  };
}
