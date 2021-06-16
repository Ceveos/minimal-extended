# .\watcher.ps1 your-new-gamemode -build    (re-)Initializes a new gamemode, erasing and copying the contents of ./your-new-gamemode/* to sbox/addons/your-new-gamemode/*, then watches
# .\watcher.ps1 your-new-gamemode           Watches for changes to ./your-new-gamemode/*, copying them to sbox/addons/your-new-gamemode/*

param (
    [Parameter(Mandatory = $true)][string]$gamemode,
    [switch]$build = $false
)

function PromptBool {
    param($Prompt)
    while ($True) {
        $answer = Read-Host -Prompt $Prompt
        if ($answer.ToLower() -eq "y") {
            return $True
        } elseif ($answer.ToLower() -eq "n") {
            return $False
        }
    }
}

if (-Not (Test-Path -Path "$($gamemode)")) {
    Write-Host "Creating new sbox\modules\$($gamemode)\ directory..."
    New-Item -ErrorAction Ignore -Type dir "$($gamemode)\"
    
    if (PromptBool -Prompt "Would you like to add sandbox-plus? (Y/N)") {
        git clone https://github.com/Nebual/sandbox-plus.git "$($gamemode)\sandbox-plus"
    }
    
    Write-Host "Add desired modules to sbox\modules\$($gamemode)\, and rerun"
    Invoke-Item "$($gamemode)\"
    return
}

$basePath = "..\addons\$($gamemode)"
$modules = dir "$($gamemode)" | ? { $_.PSISContainer }
$assetFolders = @("code", "entity", "materials", "models", "particles", "sounds")

if ($build) {
    if (Test-Path -Path "..\addons\$($gamemode)\") {
        if (-Not (Test-Path -Path "..\addons\$($gamemode)\AUTOGENERATED")) {
            # If this file is missing, this folder wasn't made by us - lets not delete their work!
            Write-Host "Error: sbox\addons\$($gamemode)\ already exists, remove it or use a different name."
            return
        }
        Write-Host "Resetting sbox\addons\$($gamemode)\..."
        Remove-Item -ErrorAction Ignore -Recurse "..\addons\$($gamemode)"
    }
    New-Item -Type dir "..\addons\$($gamemode)" > $null
    "This folder was generated by minimal-extended's watcher.ps1. Don't edit these files, instead, run sbox/workspace/watcher.ps1 and edit the source files in sbox/workspace/$($gamemode)/" | Out-File -FilePath "..\addons\$($gamemode)\AUTOGENERATED"
    foreach ($subPath in @("code\", "config\", "data\", ".addon")) {
        $newPath = "..\addons\$($gamemode)\"
        Write-Host "Copying minimal-extended $($subPath) to $($newPath)"
        New-Item -ErrorAction Ignore -Type dir (split-path $newPath -Parent)
        Copy-Item -Recurse $subPath $newPath
    }

    foreach ($module in $modules) {
        Write-Host "Copying $($module)..."
        foreach ($assetFolder in $assetFolders) {
            Copy-Item -ErrorAction Ignore -Recurse "$($gamemode)\$($module)\$($assetFolder)" "$($basePath)\"
        }
    }
}


$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $gamemode
$watcher.Filter = '*'
$watcher.IncludeSubdirectories = $true

$action = {
    $gamemode = $event.MessageData.gamemode
    $basePath = $event.MessageData.basePath
    $assetFolders = $event.MessageData.assetFolders
 
    $path = $event.SourceEventArgs.FullPath
    $changeType = $event.SourceEventArgs.ChangeType
    if ((get-item $path) -is [System.IO.DirectoryInfo]) {
        return
    }
    #$logline = "$(Get-Date), $changeType, $path"
    #Write-Host "Changed " $logline
    
    $path -match '^(?<gamemodeModule>[^\\]+\\[^\\]+)\\(?<localPath>.*)$'
    $gamemodeModule = $Matches.gamemodeModule
    $localPath = $Matches.localPath
   
    foreach ($subPath in $assetFolders) {
        if ($path.StartsWith("$($gamemodeModule)\$($subPath)")) {
            $oldPath = $path
            $newPath = "$($basePath)\$($localPath)"
            if ($changeType -eq "Renamed") {
                $oldFullPath = $event.SourceEventArgs.OldFullPath
                Write-Host "Deleting old $($oldFullPath)"
                Remove-Item $oldFullPath
                # Fallthrough to copy behaviour
            }
            if ($changeType -eq "Deleted") {
                Write-Host "Deleting $($newPath)"
                Remove-Item -Recurse $newPath
            }
            else {
                Write-Host "Copying $($oldPath) to $($newPath)"
                New-Item -Type dir (split-path $newPath -Parent)
                Copy-Item $oldPath $newPath
            }
        }
    }
}

$actionArgs = [PSCustomObject]@{
    gamemode     = $gamemode
    basePath     = $basePath
    assetFolders = $assetFolders
}

$handlers = . {
    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action -MessageData $actionArgs
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action -MessageData $actionArgs
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action -MessageData $actionArgs
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action -MessageData $actionArgs
}
$watcher.EnableRaisingEvents = $true
Write-Host
Write-Host "Watching for changes to asset directories in $($gamemode)..."


try {
    do {
        # Wait-Event waits for a second and stays responsive to events
        Wait-Event -Timeout 1
    } while ($true)
}
finally {
    $watcher.EnableRaisingEvents = $false
  
    $handlers | ForEach-Object {
        Unregister-Event -SourceIdentifier $_.Name
    }
    $handlers | Remove-Job
  
    $watcher.Dispose()
}
