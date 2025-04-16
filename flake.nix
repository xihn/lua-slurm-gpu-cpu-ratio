{
  description = "Lua slurm ratio plugin flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in pkgs.stdenv.mkDerivation {
      pname = "lua-slurm-ratio";
      version = "0.1.0";
      src = ./.;
      buildInputs = [ pkgs.lua pkgs.luarocks ];
      # No build phase since this is a Lua project.
      installPhase = ''
        mkdir -p $out/lib/lua
        cp -r slurm-cpu-gpu-ratio/*.lua $out/lib/lua/
      '';
      meta = with pkgs.lib; {
        description = "Slurm job-submit plugin for enforcing cpu/gpu ratios in Lua";
        license = licenses.mit;
        platforms = platforms.linux;
      };
    };

    devShells.x86_64-linux.default = let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in pkgs.mkShell {
      buildInputs = [ pkgs.lua pkgs.luarocks ];
      shellHook = ''
        luarocks config local_by_default true
        luarocks install busted
      '';
    };
  };
}