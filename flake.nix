{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    rust-overlay.url = "github:oxalica/rust-overlay";
    nur.url = github:polygon/nur.nix;
  };

  outputs = { self, rust-overlay, nixpkgs, nur }:
    let
      overlays = [ (import rust-overlay) ];
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        inherit overlays;
      };
      rust-deps = with pkgs; [
        (rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
          targets = [ "wasm32-unknown-unknown" ];
          extensions = [ "rust-src" ];
        }))
        rust-analyzer
        rustfmt
        pkgconfig
        lldb
        lld
        clang
        cargo-geiger
        nur.packages.x86_64-linux.wasm-server-runner
      ];
      runtime-deps = with pkgs; [
        alsa-lib
        udev
        xorg.libX11
        xorg.libXcursor
        xorg.libXrandr
        xorg.libXi
        xorg.libxcb
        libGL
        vulkan-loader
        vulkan-headers
      ];
    in
    {
      devShell.x86_64-linux =
        pkgs.mkShell {
          buildInputs = rust-deps ++ runtime-deps;
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath runtime-deps;
        };
    };
}
