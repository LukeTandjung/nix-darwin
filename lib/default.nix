inputs: self: super: {
  nixosSystem' = config: {
    class = "nixos";
    config = super.nixosSystem {
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
      specialArgs = { 
        inherit inputs;
        lib = self;
      };
      modules = [ config ];
    };
  };
}
