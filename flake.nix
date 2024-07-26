{
  inputs.nixpkgs.url = "nixpkgs/nixos-24.05";
  outputs = {nixpkgs, ...}: let
    systems = ["aarch64-linux" "aarch64-darwin" "x86_64-darwin" "x86_64-linux"];
    pkgsFor = func: (nixpkgs.lib.genAttrs systems (system: (func (import nixpkgs {inherit system;}))));
  in {
    packages = pkgsFor (pkgs: {default = pkgs.callPackage ./lxd-xattrs.nix {};});
  };
}
