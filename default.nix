# Overlay.

self: super: {
  formal = super.callPackage ./pkgs/formal.nix { };
}