{
  description = "Чисте Haskell середовище для Neovim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          haskell.compiler.ghc96
          haskellPackages.cabal-install
          haskell.packages.ghc96.haskell-language-server
          haskellPackages.fourmolu
          # Tools
          nixd # LSP nix
          nixfmt-rfc-style # formatter for nix
          haskellPackages.wai-app-static # static local web server

        ];
      };
    };
}
