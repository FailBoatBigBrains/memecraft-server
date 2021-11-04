{
  description = "Flake do memecraft-server";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    podman-rootless.url = "github:ES-Nix/podman-rootless/from-nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, podman-rootless }:
    flake-utils.lib.eachDefaultSystem (system:
      let

        pkgsAllowUnfree = import nixpkgs {
          system = "x86_64-linux";
          config = { allowUnfree = true; };
        };

        config = {
          projectDir = ./.;
        };

        hack = pkgsAllowUnfree.writeShellScriptBin "hack" ''
          # Dont overwrite customised configuration

          if ! command -v newuidmap 1 > /dev/null 2 > /dev/null; then

            if command -v apt-get 1 > /dev/null 2 > /dev/null; then
              echo 'Tentando instalar uidmap via sudo apt-get...'
              sudo apt-get update
              sudo apt-get install -y --no-install-recommends --no-install-suggests uidmap
            fi

            if command -v dnf 1 > /dev/null 2 > /dev/null; then
              echo 'Tentando instalar shadow-utils-2 via sudo dnf install...'
              sudo dnf update -y
              sudo dnf install -y shadow-utils-2
            fi
          fi

          # https://dev.to/ifenna__/adding-colors-to-bash-scripts-48g4
          echo -e '\n\n\n\e[32m\tAmbiente pronto!\e[0m\n'
          echo -e '\n\t\e[33mignore as proximas linhas...\e[0m\n\n\n'
        '';
      in
      {


        devShell = pkgsAllowUnfree.mkShell {
          buildInputs = with pkgsAllowUnfree; [
            gnumake
            hack
            podman-rootless.defaultPackage.${system}
          ];

          shellHook = ''
            # TODO: documentar esse comportamento,
            # devo abrir issue no github do nixpkgs
            export TMPDIR=/tmp

            echo "Entering the nix devShell no income back"
            hack
          '';
        };
      });
}
