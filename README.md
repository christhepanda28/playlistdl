# Audio Downloader

A self-hosted web application for downloading songs, albums, or playlists from Spotify and YouTube as MP3 files. The application provides a web interface for users to input links, which are then downloaded as audio files using `spotdl` (for Spotify) or `yt-dlp` (for YouTube).

## Features

- **Download Spotify and YouTube playlists**: Automatically detects and processes playlists based on the URL.
- **Session-based download directories**: Isolates each user session to a unique download directory.
- **Admin Mode**: Enables admin users to download directly to a specified folder on the server.
- **Progress bar and download logs**: View download progress and logs in real-time via the web interface.
- **Auto-cleanup**: Deletes temporary session download folders after a specified time.
- **Organized Downloads**: Downloads are structured by artist and album folders, maintaining organization across downloads.
<!--- **Admin mode**: Allows the admin to specify a custom directory for downloads.
-->
## Prerequisites

- **Docker** and **Docker Compose** installed on your system.

## Installation

**Run with Docker Compose**:
   Use the provided `docker-compose.yaml` configuration to start the container.
```yaml
services:
  playlistdl:
    image: tanner23456/playlistdl:v2
    container_name: playlistdl
    ports:
      - "4827:5000"
    environment:
      #Direct Server Download
      - ADMIN_USERNAME= #Insert unique username here!
      - ADMIN_PASSWORD= #Insert unique password here!

      - AUDIO_DOWNLOAD_PATH=${AUDIO_DOWNLOAD_PATH}  # Use the env variable
      - CLEANUP_INTERVAL=300  # Optional
    volumes:
      - ${AUDIO_DOWNLOAD_PATH}:${AUDIO_DOWNLOAD_PATH}  # Reference env variable here as well


```

## Usage

1. **Access the Web Interface**:
   Open a browser and navigate to `http://localhost:5000` (replace `localhost` with your server IP if remote).

2. **Download a Playlist**:
   - Enter a Spotify or YouTube playlist URL.
   - Click **Download** to start the process.
   - Monitor download progress and logs via the interface.
3. **Admin Mode**:
   - Click the **Admin** button to log in with your credentials.
   - Once logged in, a message will appear in red indicating, "Now downloading directly to your server!"
   - Enter the playlist or album link as usual, and files will be saved to the designated admin folder on your server.
<!--
3. **Admin Mode**:
   - Click the **Admin** button to log in with your credentials.
   - Once logged in, specify a custom folder name where the files will be downloaded.
-->
# Nix Module Installation

The playlistdl service can be installed and configured as a NixOS module. This guide explains how to set up and configure the service using Nix flakes.

## Quick Start

1. Add the flake to your NixOS configuration flake:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    playlistdl.url = "github:yourusername/playlistdl"; # Replace with your repo URL
  };
}
```

2. Import and enable the service in your NixOS configuration:

```nix
{
  imports = [ 
    # Import the module
    inputs.playlistdl.nixosModules.default 
  ];

  # Enable and configure the service
  services.playlistdl = {
    enable = true;
    port = 5005;  # Default is 5000
    settings = {
      audioDownloadPath = "/path/to/downloads";
      cleanupInterval = "300";
      # Optional authentication
      adminUsername = "admin";
      adminPassword = "secretpassword";
    };
  };
}
```

## Configuration Options

### Basic Options

- `enable`: Boolean to enable/disable the service
- `port`: Port number for the web interface (default: 5000)

### Environment Variables

All environment variables are configured through the `settings` attribute set using camelCase notation. They are automatically converted to SCREAMING_SNAKE_CASE environment variables.

Example conversions:
- `audioDownloadPath` → `AUDIO_DOWNLOAD_PATH`
- `cleanupInterval` → `CLEANUP_INTERVAL`
- `adminUsername` → `ADMIN_USERNAME`

### Common Settings

```nix
settings = {
  # Required
  audioDownloadPath = "/path/to/downloads";  # Directory for downloaded files
  
  # Optional
  cleanupInterval = "300";     # Cleanup interval in seconds
  adminUsername = "admin";     # Admin interface username
  adminPassword = "password";  # Admin interface password
};
```

## Permissions and Storage

The service runs as the `playlistdl` user and group. The specified `audioDownloadPath` will be:
- Created automatically if it doesn't exist
- Owned by the playlistdl user and group
- Set with permissions 750 (rwxr-x---)

## Firewall Configuration

The service automatically configures the firewall to allow incoming connections on the specified port.

## Systemd Service Management

Once installed, you can manage the service using standard systemd commands:

```bash
# Start the service
sudo systemctl start playlistdl

# Check status
sudo systemctl status playlistdl

# View logs
sudo journalctl -u playlistdl

# Restart service
sudo systemctl restart playlistdl
```

## Upgrading

To upgrade the service, update the flake input in your NixOS configuration and rebuild:

```bash
sudo nixos-rebuild switch
```

## Troubleshooting

Common issues and solutions:

1. **Service won't start**: Check logs with `journalctl -u playlistdl`
2. **Permission denied**: Ensure `audioDownloadPath` is accessible by the playlistdl user
3. **Port already in use**: Change the port number in your configuration
4. **Environment variables not set**: Verify your settings in the NixOS configuration

For more help, check the [project repository](https://github.com/yourusername/playlistdl) or open an issue.
## Configuration

### Environment Variables

- `CLEANUP_INTERVAL`: (Optional) Sets the cleanup interval for session-based download folders. Defaults to `300` seconds (5 minutes) if not specified.
- `ADMIN_USERNAME` and `ADMIN_PASSWORD`:(Optional) Sets the login credentials for admin access.
- `AUDIO_DOWNLOAD_PATH`: Sets the folder for admin-mode downloads. Files downloaded as an admin are stored here. This is set in your .env file.

## Technical Overview

- **Backend**: Flask application that handles download requests and manages session-based directories.
- **Frontend**: Simple HTML/JavaScript interface for input, progress display, and log viewing.
- **Tools**:
  - `spotdl` for downloading Spotify playlists.
  - `yt-dlp` for downloading YouTube playlists as MP3s.

## Notes

- This application is intended for personal use. Make sure to follow copyright laws and only download media you’re authorized to use.
- Ensure that the `downloads` directory has appropriate permissions if running on a remote server.

## Troubleshooting

- **Permissions**: Ensure the `downloads` directory has the correct permissions for Docker to write files.
- **Port Conflicts**: If port 5000 is in use, adjust the port mapping in the `docker-compose.yaml` file.

## Support This Project

If you like this project, consider supporting it with a donation!

[![Donate via Stripe](https://img.shields.io/badge/Donate-Stripe-blue?style=flat&logo=stripe)](https://buy.stripe.com/6oEdU3dWS19C556dQQ)

