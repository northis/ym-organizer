# Yandex Music Downloader and Organizer
# This script combines the functionality of !RUN.cmd and temp.ps1
# 1. Downloads new music from Yandex Music
# 2. Organizes files by ID
# 3. Renames files according to the naming convention

# Load configuration from external file
$configFile = Join-Path -Path $PSScriptRoot -ChildPath "config.ps1"
$configTemplateFile = Join-Path -Path $PSScriptRoot -ChildPath "config.template.ps1"

# Check if config.ps1 exists, if not, check if we need to create it from template
if (Test-Path -Path $configFile) {
    Write-Host "Loading configuration from $configFile"
    . $configFile
} elseif (Test-Path -Path $configTemplateFile) {
    Write-Host "Configuration file not found. Creating from template..."
    Copy-Item -Path $configTemplateFile -Destination $configFile
    Write-Host "Please edit $configFile with your settings and run the script again."
    Write-Host "This file is ignored by Git to keep your personal settings private."
    exit
} else {
    Write-Host "Configuration template file not found. Please, fill config.ps1 file."
    exit 1;    
}

# ID position number for file metadata
$idPosNumber = 26

# Function to check if a track already exists in the target directory
function Test-TrackExists {
    param (
        [string]$Author,
        [string]$Title,
        [string]$TargetDirectory
    )
    
    $shellCom = New-Object -ComObject Shell.Application
    $sDirectory = $shellCom.NameSpace($TargetDirectory)
    
    foreach ($file in (Get-ChildItem -Path $TargetDirectory)) {
        $sFile = $sDirectory.ParseName($file.Name)
        $fileAuthor = $sDirectory.GetDetailsOf($sFile, 20)
        $fileTitle = $sDirectory.GetDetailsOf($sFile, 21)
        
        if ($fileAuthor -eq $Author -and $fileTitle -eq $Title) {
            return $true
        }
    }
    
    return $false
}

# Function to pre-scan the target directory and get existing tracks
function Get-ExistingTracks {
    param (
        [string]$TargetDir
    )
    
    Write-Host "Pre-scanning target directory for existing tracks..."
    
    # Create target directory if it doesn't exist
    if (-not (Test-Path -Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
        Write-Host "Target directory created."
        return @{}
    }
    
    # Initialize Shell.Application object
    $shellCom = New-Object -ComObject Shell.Application
    $targetDirectory = $shellCom.NameSpace($TargetDir)
    
    # Get existing tracks from target directory
    $existingTracks = @{}
    foreach ($file in (Get-ChildItem -Path $TargetDir -Filter "*.mp3")) {
        $shellFile = $targetDirectory.ParseName($file.Name)
        $author = $targetDirectory.GetDetailsOf($shellFile, 20)
        $title = $targetDirectory.GetDetailsOf($shellFile, 21)
        
        if ($author -and $title) {
            $key = "$author - $title"
            $existingTracks[$key] = @{
                Author = $author
                Title = $title
                File = $file
            }
        }
    }
    
    Write-Host "Found $($existingTracks.Count) existing tracks in target directory."
    return $existingTracks
}

# Function to find the most recent track in the target directory
function Get-MostRecentTrack {
    param (
        [string]$TargetDir
    )
    
    Write-Host "Finding the most recent track in target directory..."
    
    # Create target directory if it doesn't exist
    if (-not (Test-Path -Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
        Write-Host "Target directory created."
        return $null
    }
    
    # Initialize Shell.Application object
    $shellCom = New-Object -ComObject Shell.Application
    $targetDirectory = $shellCom.NameSpace($TargetDir)
    
    # Get all tracks from target directory
    $tracks = @()
    $files = Get-ChildItem -Path $TargetDir -Filter "*.mp3" | Sort-Object -Property Name -descending | Select-Object -First 1 
    foreach ($file in $files) {
        $shellFile = $targetDirectory.ParseName($file.Name)
        $author = $targetDirectory.GetDetailsOf($shellFile, 20)
        $title = $targetDirectory.GetDetailsOf($shellFile, 21)
        
        if ($author -and $title) {
            $tracks += @{
                Name = $file.Name
                Author = $author
                Title = $title
                File = $file
            }
        }
    }
    
    # If no tracks found, return null
    if ($tracks.Count -eq 0) {
        Write-Host "No tracks found in target directory."
        return $null
    }
    
    $mostRecentTrack = $tracks[0];
    
    Write-Host "Most recent track found: $($mostRecentTrack.Author) - $($mostRecentTrack.Title) (File: $($mostRecentTrack.Name))"
    return $mostRecentTrack
}

# Function to download new music
function Download-NewMusic {
    param (
        [string]$PlaylistUrl,
        [string]$SourceDir,
        [string]$TargetDir,
        [string]$Cookie,
        [hashtable]$MostRecentTrack
    )
    
    Write-Host "Starting music download from Yandex Music..."
    
    # Create source directory if it doesn't exist
    if (-not (Test-Path -Path $SourceDir)) {
        New-Item -ItemType Directory -Path $SourceDir -Force | Out-Null
    }
    
    # Change to src directory and run the perl script
    $currentLocation = Get-Location
    Set-Location -Path "$PSScriptRoot\src"
    
        $author = $MostRecentTrack.Author -replace '"', '\"'  # Escape quotes
        $title = $MostRecentTrack.Title -replace '"', '\"'    # Escape quotes

    # Run the perl script
    perl ya.pl -u $PlaylistUrl --bitrate 320 --path $SourceDir --cookie $Cookie --last_title $title --last_author $author
    
    # Return to original location
    Set-Location -Path $currentLocation    
    Write-Host "Download completed."
}

# Function to get track details
function Get-TrackDetails {
    param (
        [System.IO.FileInfo]$File,
        [object]$ShellDirectory
    )
    
    $shellFile = $ShellDirectory.ParseName($File.Name)
    $id = $ShellDirectory.GetDetailsOf($shellFile, $idPosNumber)
    $author = $ShellDirectory.GetDetailsOf($shellFile, 20)
    $title = $ShellDirectory.GetDetailsOf($shellFile, 21)
    
    # Convert ID to integer, default to 0 if conversion fails
    try {
        $idNumber = [int]$id
    } catch {
        $idNumber = 0
    }
    
    return @{
        ID = $idNumber
        Author = $author
        Title = $title
        File = $File
    }
}

# Function to organize and rename new tracks
function Organize-NewTracks {
    param (
        [string]$SourceDir,
        [string]$TargetDir
    )
    
    Write-Host "Organizing new tracks..."
    
    # Create target directory if it doesn't exist
    if (-not (Test-Path -Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
    
    # Initialize Shell.Application objects
    $shellCom = New-Object -ComObject Shell.Application
    $sourceDirectory = $shellCom.NameSpace($SourceDir)
    $targetDirectory = $shellCom.NameSpace($TargetDir)
    
    # Get existing tracks from target directory for comparison
    $existingTracks = @{}
    foreach ($file in (Get-ChildItem -Path $TargetDir)) {
        $trackDetails = Get-TrackDetails -File $file -ShellDirectory $targetDirectory
        $key = "$($trackDetails.Author) - $($trackDetails.Title)"
        $existingTracks[$key] = $trackDetails
    }
    
    # Get new tracks from source directory
    $newTracks = @()
    foreach ($file in (Get-ChildItem -Path $SourceDir)) {
        $trackDetails = Get-TrackDetails -File $file -ShellDirectory $sourceDirectory
        $key = "$($trackDetails.Author) - $($trackDetails.Title)"
        
        # Check if this track already exists in the target directory
        if (-not $existingTracks.ContainsKey($key)) {
            $newTracks += $trackDetails
        } else {
            Write-Host "Skipping existing track: $key"
        }
    }
    
    # If no new tracks, exit
    if ($newTracks.Count -eq 0) {
        Write-Host "No new tracks found."
        return
    }
    
    Write-Host "Found $($newTracks.Count) new tracks."
    
    # Sort new tracks by ID in descending order (highest ID first)
    # Use a script block for sorting to ensure we're comparing the actual numeric values
    $sortedNewTracks = $newTracks | Sort-Object -Property { [int]$_.ID } -Descending
    
    # Display sorted tracks for verification
    Write-Host "Sorted tracks by ID (descending):"
    foreach ($track in $sortedNewTracks) {
        Write-Host "  ID: $($track.ID), Author: $($track.Author), Title: $($track.Title)"
    }
    
    # Get the highest ID from existing tracks
    $highestExistingId = 0
    foreach ($track in $existingTracks.Values) {
        if ($track.ID -gt $highestExistingId) {
            $highestExistingId = $track.ID
        }
    }
    
    # Process and copy new tracks
    $nextId = $highestExistingId + 1
    foreach ($track in $sortedNewTracks) {
        $sourceFile = $track.File.FullName
        $targetFileName = "$($track.File.Name)"
        $targetFile = Join-Path -Path $TargetDir -ChildPath $targetFileName
        
        # Copy file to target directory
        Copy-Item -Path $sourceFile -Destination $targetFile -Force
        
        # Set ID property for the copied file
        $copiedFile = Get-Item -Path $targetFile
        $shellFile = $targetDirectory.ParseName($copiedFile.Name)
        
        # Set the ID property (this is just a placeholder - actual property setting will happen during rename)
        $track.NewID = $nextId
        $nextId++
    }
    
    Write-Host "All new tracks copied to target directory."
    return $sortedNewTracks
}

# Function to rename tracks according to the naming convention
function Rename-NewTracks {
    param (
        [array]$NewTracks,
        [string]$TargetDir
    )
    
    Write-Host "Renaming new tracks..."
    
    Add-Type -Path "lib\TaglibSharp.dll";
    
    
    foreach ($track in $NewTracks) {
        $file = Get-Item -Path (Join-Path -Path $TargetDir -ChildPath $track.File.Name)
        
        $author = $track.Author
        $title = $track.Title
        $newId = $track.NewID
        
        $fileTag = [TagLib.File]::Create($file)
        $fileTag.Tag.Track = $newId
        $fileTag.Save()
        
        # Create new filename according to the pattern
        $newName = "$($newId.ToString().PadLeft(4, '0')). $author - $title.mp3"
        
        # Replace invalid characters
        $chars = [IO.Path]::GetInvalidFileNameChars()
        $newName = $newName.Split($chars) -join '_'
        
        # Rename the file
        Rename-Item -LiteralPath $file.FullName -NewName $newName
        Write-Host "Renamed: $newName"
    }
    
    Write-Host "All new tracks renamed successfully."
}

# Main execution flow
function Start-MusicDownloadAndOrganize {
    param (
        [string]$PlaylistUrl = $playlistUrl,
        [string]$SourceDir = $sourceDir,
        [string]$TargetDir = $targetDir,
        [string]$Cookie = $cookie
    )
    
    # Step 1: Find the most recent track in the target directory
    $mostRecentTrack = Get-MostRecentTrack -TargetDir $TargetDir
    
    # Step 2: Download new music
    Download-NewMusic -PlaylistUrl $PlaylistUrl -SourceDir $SourceDir -TargetDir $TargetDir -Cookie $Cookie -MostRecentTrack $mostRecentTrack
    
    # Step 3: Organize new tracks
    $newTracks = Organize-NewTracks -SourceDir $SourceDir -TargetDir $TargetDir
    
    # Step 4: Rename new tracks if any were found
    if ($newTracks -and $newTracks.Count -gt 0) {
        Rename-NewTracks -NewTracks $newTracks -TargetDir $TargetDir
    }
    
    Write-Host "Music download and organization process completed."
}

# Run the main function
Start-MusicDownloadAndOrganize
