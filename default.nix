{ pkgs ? import (
  builtins.fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/22.05.tar.gz";
    sha256 = "0d643wp3l77hv2pmg2fi7vyxn4rwy0iyr8djcw1h5x72315ck9ik";
  }
) {} }:

with pkgs;

mkShell {
  buildInputs = [
    (python310.withPackages (ps: with ps; [
      virtualenv
    ]))
  ];
  shellHook = ''
    [ ! -d venv ] && python -m virtualenv venv
    source venv/bin/activate
    pip install circup
  '';
}
