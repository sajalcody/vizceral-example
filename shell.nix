{
 withHoogle ? true
}:
let
 config = {
   packageOverrides = pkgs: rec {
     haskellPackages = pkgs.haskellPackages.override {
       overrides = self: super: rec {
         ghc =
           super.ghc // { withPackages = if withHoogle then super.ghc.withHoogle else super.ghc ; };
         ghcWithPackages =
           self.ghc.withPackages;
         vizceral-example =
           self.callPackage ./vizceral-example.nix { };
         stream-web =
           self.callPackage ./stream-web.nix { };
         streamly =
           self.callPackage ./streamly.nix { };
       };
     };
   };
 };
 pkgs = import <nixpkgs> { inherit config; };
 drv = pkgs.haskellPackages.vizceral-example;
in
 if pkgs.lib.inNixShell
   then
     drv.env.overrideAttrs(attrs:
       { buildInputs =
         with pkgs.haskellPackages;
         [
           cabal-install
           cabal2nix
           ghcid
           hindent
           hlint
           stylish-haskell
         ] ++ [ zlib ] ++ attrs.buildInputs;
       })
       else drv.overrideAttrs(attrs:
       {
         buildInputs = attrs.buildInputs ++ [ pkgs.zlib ];
       })