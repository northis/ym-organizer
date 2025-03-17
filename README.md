See original readme https://github.com/kaimi-io/yandex-music-download/blob/master/README.md

## PowerShell Script for Automated Downloads

This repository now includes a PowerShell script for automating the download and organization of music from Yandex Music.

### Features
- Automatically downloads new tracks from a Yandex Music playlist
- Organizes tracks by ID in a target directory
- Renames files according to a consistent naming convention
- Stops downloading when it finds an already downloaded track
- Configurable through an external configuration file

### Setup and Usage

1. Run the PowerShell script for the first time:
   ```powershell
   .\DownloadAndOrganizeMusic.ps1
   ```
   This will create a `config.ps1` file from the template.

2. Edit the `config.ps1` file to set your:
   - Source directory (where new music will be downloaded)
   - Target directory (where music will be organized)
   - Yandex Music cookie (for authentication)
   - Playlist URL (the playlist you want to download)

3. Run the PowerShell script again:
   ```powershell
   .\DownloadAndOrganizeMusic.ps1
   ```

4. The script will:
   - Find the most recent track in your target directory
   - Download only new tracks from the playlist
   - Organize and rename the new tracks in your target directory

### Configuration File

The configuration uses two files:
- `config.template.ps1`: A template with default values (included in the repository)
- `config.ps1`: Your personal configuration file (ignored by Git for privacy)

The `config.ps1` file contains all the necessary configuration variables:

```powershell
# Source and target directories
$sourceDir = "D:\Music\Downloads"
$targetDir = "D:\Music\Library"

# Yandex Music authentication
$cookie = "YOUR_COOKIE_HERE"

# Playlist URL
$playlistUrl = "https://music.yandex.ru/users/username/playlists/playlistid"
```

Your personal settings in `config.ps1` will not be committed to Git, ensuring your private information remains secure.

## FAQ
### What is the cause for "[ERROR] Yandex.Music is not available"?
Currently Yandex Music is available only for Russia and CIS countries. For other countries you should either acquire paid subscription or use it through proxy (```--proxy``` parameter) from one of those countries. Thus it is possible to download from any country if you have an active Yandex.Music service subscription (https://music.yandex.ru/pay).

## Contribute
If you want to help make Yandex Music Downloader better the easiest thing you can do is to report issues and feature requests. Or you can help in development.

## License
Yandex Music Downloader Copyright 2013-2022 by Kaimi (Sergey Belov) - https://kaimi.io.

Yandex Music Downloader is free software: you can redistribute it and/or modify it under the terms of the Massachusetts Institute of Technology (MIT) License.

You should have received a copy of the MIT License along with Yandex Music Downloader. If not, see [MIT License](LICENSE).

Modified by Mikhail Berdnikov (c) 2025, https://github.com/northis/ (The Powershell organizer and perl changes)
This fork uses TagLibSharp.dll, which is a C# port of the TagLib library by LGPL-2.1 license. You can obtain it here: https://github.com/mono/taglib-sharp
