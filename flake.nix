{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.poetry2nix.url = "github:nix-community/poetry2nix";

  outputs = { self, nixpkgs, poetry2nix }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});
      over = final: prev: {
      };
    in
    {
      packages = forAllSystems (system: let
        inherit (poetry2nix.lib.mkPoetry2Nix { pkgs = pkgs.${system}; }) mkPoetryApplication;
      in {
        default = mkPoetryApplication { projectDir = self; };
      });

      devShells = forAllSystems (system: let
        inherit (poetry2nix.lib.mkPoetry2Nix { pkgs = pkgs.${system}; }) mkPoetryEnv overrides;
      in {
        default = pkgs.${system}.mkShellNoCC {
          packages = with pkgs.${system}; [
            (mkPoetryEnv { projectDir = self; overrides = overrides.withDefaults over; })
            poetry
            pyright
          ];
        };
      });

      nixosModules.default = {lib, config, options, pkgs, ...}:
        with lib; with lib.satrn;
        let inherit (poetry2nix.lib.mkPoetry2Nix { pkgs = pkgs; }) mkPoetryApplication;
            app = mkPoetryApplication { projectDir = self; };
            cfg = config.satrn.programs.viacpu;
        in {
           options.satrn.programs.viacpu = with types; {
             enable = mkBoolOpt false "Enable minimal system configuration";
           };

           config = mkIf cfg.enable {
             systemd.services.viacpu = {
               wantedBy = ["graphical.target"];
               serviceConfig = {
                 Type = "simple";
                 Restart = "always";
                 User = "sora";
                 ExecStart = "${app.out}/bin/viacpu";
               };
             };

             environment.systemPackages = [ app ];
           };
        };
    };
}
