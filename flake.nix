{
  description = "playlistdl - Playlist Download Service";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        pythonEnv = pkgs.python312.withPackages (ps:
          with ps; [
            flask
            pip
          ]);

        # Main service package
        servicePackage = pkgs.stdenv.mkDerivation {
          name = "playlistdl";
          src = ./.;

          buildInputs = [
            pythonEnv
            pkgs.ffmpeg
            pkgs.yt-dlp
            pkgs.spotdl
          ];

          installPhase = ''
            mkdir -p $out/bin
            mkdir -p $out/app
            cp -r app/* $out/app/
            cp -r web $out/app/

            # Create wrapper script
            cat > $out/bin/playlistdl <<EOF
            #!${pkgs.bash}/bin/bash
            export PATH="${pkgs.lib.makeBinPath [pythonEnv pkgs.ffmpeg pkgs.yt-dlp pkgs.spotdl]}"
            exec ${pythonEnv}/bin/python $out/app/main.py
            EOF

            chmod +x $out/bin/playlistdl
          '';
        };

        # Helper function to convert camelCase to SCREAMING_SNAKE_CASE
        toEnvVar = name: let
          # Insert underscore before capital letters and convert to uppercase
          chars = pkgs.lib.stringToCharacters name;
          insertedUnderscores = pkgs.lib.concatStrings (
            pkgs.lib.lists.foldr (
              c: acc:
                if (c >= "A" && c <= "Z")
                then "_${c}${acc}"
                else "${c}${acc}"
            ) ""
            chars
          );
        in
          pkgs.lib.toUpper (pkgs.lib.removePrefix "_" insertedUnderscores);
      in {
        packages.default = servicePackage;

        # NixOS module for the service
        nixosModules.default = {
          config,
          lib,
          pkgs,
          ...
        }: {
          options.services.playlistdl = {
            enable = lib.mkEnableOption "playlistdl service";
            port = lib.mkOption {
              type = lib.types.int;
              default = 5000;
              description = "Port to listen on";
            };
            settings = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = {};
              description = "Environment variables for playlistdl (in camelCase)";
              example = lib.literalExpression ''
                {
                  audioDownloadPath = "/path/to/downloads";
                  cleanupInterval = "300";
                  adminUsername = "admin";
                  adminPassword = "password";
                }
              '';
            };
          };

          config = lib.mkIf config.services.playlistdl.enable {
            systemd.services.playlistdl = {
              description = "Playlist Download Service";
              wantedBy = ["multi-user.target"];
              after = ["network.target"];

              environment = let
                # Convert all settings to environment variables
                envVars =
                  lib.mapAttrs' (name: value: {
                    name = toEnvVar name;
                    value = toString value;
                  })
                  config.services.playlistdl.settings;
              in
                envVars;

              serviceConfig = {
                ExecStart = "${servicePackage}/bin/playlistdl";
                User = "playlistdl";
                Group = "playlistdl";
                WorkingDirectory = "/var/lib/playlistdl";
                StateDirectory = "playlistdl";
                RuntimeDirectory = "playlistdl";
              };
            };

            users.users.playlistdl = {
              isSystemUser = true;
              group = "playlistdl";
              home = "/var/lib/playlistdl";
              createHome = true;
            };

            users.groups.playlistdl = {};

            networking.firewall = {
              allowedTCPPorts = [config.services.playlistdl.port];
            };

            # Ensure download directory exists if audioDownloadPath is set
            systemd.tmpfiles.rules = lib.mkIf (config.services.playlistdl.settings ? audioDownloadPath) [
              "d '${config.services.playlistdl.settings.audioDownloadPath}' 0750 playlistdl playlistdl -"
            ];
          };
        };
      }
    );
}
