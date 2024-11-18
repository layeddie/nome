# This flake was initially generated by fh, the CLI for FlakeHub (version 0.1.6)
{
  description = "Nome: my Nix home";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    fh = { url = "https://flakehub.com/f/DeterminateSystems/fh/*"; inputs.nixpkgs.follows = "nixpkgs"; };
    jelly = { url = "github:lucperkins/jelly"; inputs.nixpkgs.follows = "nixpkgs"; };
    fenix = { url = "https://flakehub.com/f/nix-community/fenix/0.1.*"; inputs.nixpkgs.follows = "nixpkgs"; };
    flake-checker = { url = "https://flakehub.com/f/DeterminateSystems/flake-checker/*"; inputs.nixpkgs.follows = "nixpkgs"; };
    home-manager = { url = "https://flakehub.com/f/nix-community/home-manager/0.2405.*"; inputs.nixpkgs.follows = "nixpkgs"; };
    nix-darwin = { url = "github:LnL7/nix-darwin"; inputs.nixpkgs.follows = "nixpkgs"; };
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2405.*";
    nixpkgs-unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*";
    nuenv = { url = "https://flakehub.com/f/DeterminateSystems/nuenv/0.1.*"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = inputs:
    let
      supportedSystems = [ "aarch64-darwin" ];
      forEachSupportedSystem = f: inputs.nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.self.overlays.default ];
        };
        inherit system;
      });

      stateVersion = "24.05";
      system = "aarch64-darwin";
      username = "lucperkins";
      caches = {
        nixos-org = {
          cache = "https://cache.nixos.org";
          publicKey = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
        };
        nix-community = {
          cache = "https://nix-community.cachix.org";
          publicKey = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
        };
      };
    in
    {
      devShells = forEachSupportedSystem ({ pkgs, system }: {
        default =
          let
            darwinRebuild = inputs.nix-darwin.packages.${system}.darwin-rebuild;
            reload = pkgs.writeScriptBin "reload" ''
              set -e
              echo "Running darwin-rebuild switch"
              sudo ${darwinRebuild}/bin/darwin-rebuild switch --flake .
              echo "Refreshing zshrc"
              ${pkgs.zsh}/bin/zsh -c "source ${pkgs.homeDirectory}/.zshrc"
              echo "DONE"
            '';
          in
          pkgs.mkShell {
            name = "nome";
            packages = with pkgs; [
              nixpkgs-fmt
              reload
            ];
          };
      });

      overlays.default = final: prev: {
        inherit username system;
        homeDirectory =
          if (prev.stdenv.isDarwin)
          then "/Users/${username}"
          else "/home/${username}";
        rev = inputs.self.rev or inputs.self.dirtyRev or null;
        fh = inputs.fh.packages.${system}.default;
        flake-checker = inputs.flake-checker.packages.${system}.default;
        jelly = inputs.jelly.packages.${system}.default;
        rustToolchain = with inputs.fenix.packages.${system};
          combine (with stable; [
            cargo
            clippy
            rustc
            rustfmt
            rust-src
          ]);

        # Packages from Nixpkgs unstable
        gleam = inputs.nixpkgs-unstable.legacyPackages.${system}.gleam;
      };

      darwinConfigurations."${username}-${system}" = inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          { system.stateVersion = 1; }
          inputs.determinate.darwinModules.default
          inputs.self.darwinModules.base
          inputs.self.darwinModules.caching
          inputs.home-manager.darwinModules.home-manager
          inputs.self.darwinModules.home-manager
        ];
      };

      darwinModules = {
        base = { pkgs, ... }: import ./nix-darwin/base {
          inherit pkgs;
          overlays = [
            inputs.nuenv.overlays.default
            inputs.self.overlays.default
          ];
        };

        caching = { ... }: import ./nix-darwin/caching {
          inherit caches username;
        };

        home-manager = { pkgs, ... }: import ./home-manager {
          inherit pkgs stateVersion username;
        };
      };

      nixosConfigurations = rec {
        default = simple;

        simple = inputs.nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [ ./nixos/configuration.nix ./nixos/hardware-configuration.nix ];
        };
      };

      templates = import
        ./templates;
    };
}
