# Configuration template file for Yandex Music Downloader
# Copy this file to config.ps1 and edit the values to match your environment
# config.ps1 is ignored by Git to keep your personal settings private

#---------------------------------------------------------------------------
# Directory paths
#---------------------------------------------------------------------------
# Source directory where new music will be downloaded
$sourceDir = "D:\Music\Downloads"

# Target directory where music will be organized and stored
$targetDir = "D:\Music\Library"

#---------------------------------------------------------------------------
# Yandex Music credentials
#---------------------------------------------------------------------------
# Your Yandex Music cookie for authentication
# To get this value:
# 1. Log in to Yandex Music in your browser
# 2. Open Developer Tools (F12)
# 3. Go to the Network tab
# 4. Refresh the page
# 5. Click on any request to music.yandex.ru
# 6. In the Headers tab, find the Cookie header
# 7. Copy the entire cookie value
$cookie = "YOUR_COOKIE_HERE"

#---------------------------------------------------------------------------
# Playlist URL
#---------------------------------------------------------------------------
# URL of the Yandex Music playlist you want to download
# Example: https://music.yandex.ru/users/username/playlists/playlistid
$playlistUrl = "https://music.yandex.ru/users/username/playlists/playlistid"
