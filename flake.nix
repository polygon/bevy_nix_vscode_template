{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    rust-overlay.url = "github:oxalica/rust-overlay/stable";
    wasm-server-runner.url = "github:polygon/wasm-server-runner";
    naersk.url = "github:nix-community/naersk";
  };

  outputs = { self, rust-overlay, nixpkgs, wasm-server-runner, naersk }:
    let
      systems = [ "aarch64-linux" "i686-linux" "x86_64-linux" ];
      overlays = [ (import rust-overlay) ];
      program_name = "bevy_nix_vscode_template";
      version = "0.18.0";
    in builtins.foldl' (outputs: system:

      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit overlays system; };

        rust-bin = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-unknown-unknown" ];
          extensions = [ "rust-src" ];
        };
        naersk-lib = naersk.lib.${system}.override {
          cargo = rust-bin;
          rustc = rust-bin;
        };

        rust-dev-deps = with pkgs; [
          rust-analyzer
          rustfmt
          lldb
          cargo-geiger
          renderdoc
          wasm-server-runner.packages.${system}.wasm-server-runner
        ];
        build-deps = with pkgs; [ pkg-config mold clang makeWrapper lld ];
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
          libxkbcommon
          kdePackages.wayland.dev
          kdePackages.wayland.out
        ];
      in {
        devShell.${system} = let
          all_deps = runtime-deps ++ build-deps ++ rust-dev-deps
            ++ [ rust-bin ];
        in pkgs.mkShell {
          buildInputs = all_deps;
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (all_deps);
          PROGRAM_NAME = program_name;
          shellHook = ''
            export CARGO_MANIFEST_DIR=$(pwd)
          '';
        };
        packages.${system} = {
          app = naersk-lib.buildPackage {
            pname = program_name;
            root = ./.;
            inherit version;
            buildInputs = runtime-deps;
            nativeBuildInputs = build-deps;
            overrideMain = attrs: {
              fixupPhase = ''
                wrapProgram $out/bin/${program_name} \
                  --prefix LD_LIBRARY_PATH : ${
                    pkgs.lib.makeLibraryPath runtime-deps
                  } \
                  --set CARGO_MANIFEST_DIR $out/share/${program_name}
                mkdir -p $out/share/${program_name}
                cp -a assets $out/share/${program_name}'';
              patchPhase = ''
                sed -i s/\"dynamic_linking\"// Cargo.toml
              '';
            };
          };
          wasm = self.packages.${system}.app.overrideAttrs (final: prev: {
            CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
            fixupPhase = "";
          });
        };
        defaultPackage.${system} = self.packages.${system}.app;
        apps.${system}.wasm = {
          type = "app";
          program = "${pkgs.writeShellScript "wasm-run" "${
              wasm-server-runner.packages.${system}.wasm-server-runner
            }/bin/wasm-server-runner ${
              self.packages.${system}.wasm
            }/bin/${program_name}.wasm"}";
        };
      }) { } systems;

}
