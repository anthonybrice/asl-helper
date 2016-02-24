# ASL-helper.nix

let
  pkgs = import <nixpkgs> {};
  stdenv = pkgs.stdenv;
in rec {
  asl-helper = stdenv.mkDerivation rec {
    name = "asl-helper";
    version = "0.0.1";
    system = builtins.currentSystem;

    src = pkgs.fetchFromGitHub {
      owner = "anthonybrice";
      repo = "asl-helper";
      rev = "HEAD";
      sha256 = "0fkw54ig3lsxp3ams9bnkgzc9l9wqxrc33gqsws7xwr3pgkipi4a";
    };

    builder = ./builder.sh;

    #buildInputs = [ pkgs.elmPackages ];
  };
}
