Start-Transcript -Path "$env:TEMP\script-log.txt" -Append
Write-Host "Starting the script..." -ForegroundColor Green

$ErrorActionPreference = "Stop"
Write-Host "This script is designed to work only on Windows." -ForegroundColor Yellow

Function Check-Installation {
    param(
        [string]$appName,
        [string]$installPath
    )

    if (Test-Path $installPath) {
        Write-Host "$appName is installed." -ForegroundColor Cyan
        return $true
    } else {
        Write-Host "$appName is not installed. Please check if it is correctly installed on your system." -ForegroundColor Yellow
        return $false
    }
}

Function Copy-Data {
    param(
        [string]$source,
        [string]$destination
    )

    if (Test-Path $source) {
        if (-not (Test-Path $destination)) {
            New-Item -Path $destination -ItemType Directory -Force
            Write-Host "New destination folder created: $destination" -ForegroundColor Green
        }

        Write-Host "Copying data from '$source' to '$destination'..." -ForegroundColor Cyan
        try {
            Copy-Item -Path "$source\*" -Destination $destination -Recurse -Force
            Write-Host "Data copied successfully!" -ForegroundColor Green
        } catch {
            Write-Host "Error copying data: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Source folder '$source' not found. No action will be taken." -ForegroundColor Yellow
    }
}

$chosenDirectory = Read-Host "Enter the full path where the 'navegator' folder is located (example: C:\Test\)"
$navigatorFolder = Join-Path -Path $chosenDirectory -ChildPath "navegator"

if (-not (Test-Path $navigatorFolder)) {
    New-Item -Path $navigatorFolder -ItemType Directory -Force
    Write-Host "The 'navegator' folder was created successfully." -ForegroundColor Green
}
$apps = @(
    @{Name = "Edge"; Path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"; RegKey = "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge"},
    @{Name = "Chrome"; Path = "$env:LOCALAPPDATA\Google\Chrome\User Data"; RegKey = "HKLM:\\SOFTWARE\\Policies\\Google\\Chrome"},
    @{Name = "Brave"; Path = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"; RegKey = "HKLM:\\SOFTWARE\\Policies\\BraveSoftware\\Brave-Browser"},
    @{Name = "Opera"; Path = "$env:LOCALAPPDATA\Opera Software\Opera Stable"; RegKey = "HKLM:\\SOFTWARE\\Policies\\Opera Software\\Opera"},
    @{Name = "Discord"; Path = "$env:LOCALAPPDATA\Discord"; RegKey = "HKLM:\\SOFTWARE\\Policies\\Discord"}
)

Write-Host "Choose an application to configure:" -ForegroundColor Cyan
for ($i = 0; $i -lt $apps.Length; $i++) {
    Write-Host "$($i + 1) - $($apps[$i].Name)"
}

$choice = Read-Host "Enter the number of the desired application"

if ($choice -ge 1 -and $choice -le $apps.Length) {
    $selectedApp = $apps[$choice - 1]
    $appPath = $selectedApp.Path
    $regPath = $selectedApp.RegKey
    
    Write-Host "Choose an action:" -ForegroundColor Cyan
    Write-Host "1 - Configure (Move data to the 'navegator' folder and update settings)"
    Write-Host "2 - Revert (Restore original settings and move data back to the original location)"
    
    $action = Read-Host "Enter the number of the desired action"
    
    if ($action -eq "1") {
        if (Check-Installation -appName $selectedApp.Name -installPath $appPath) {
            $destinationFolder = Join-Path -Path "$navigatorFolder\$($selectedApp.Name)" -ChildPath "Data"
            if (-not (Test-Path $destinationFolder)) {
                New-Item -Path $destinationFolder -ItemType Directory -Force
                Write-Host "Created folder: $destinationFolder" -ForegroundColor Green
            }
            Copy-Data -source $appPath -destination $destinationFolder
            
            Remove-Item -Path "$appPath" -Recurse -Force
            Write-Host "Original data removed from $appPath." -ForegroundColor Yellow

            if ($regPath) {
                if (-not (Test-Path $regPath)) {
                    New-Item -Path $regPath -Force
                }
                Set-ItemProperty -Path $regPath -Name "UserDataDir" -Value "$destinationFolder"
                Set-ItemProperty -Path $regPath -Name "ForceUserDataDir" -Value 1
            }
            Write-Host "$($selectedApp.Name) configured successfully." -ForegroundColor Green
        }
    } elseif ($action -eq "2") {
        $dataFolder = Join-Path -Path "$navigatorFolder\$($selectedApp.Name)" -ChildPath "Data"

        if (Test-Path $dataFolder) {
            if (-not (Test-Path $appPath)) {
                New-Item -Path $appPath -ItemType Directory -Force
                Write-Host "Original folder recreated: $appPath" -ForegroundColor Green
            }

            Copy-Data -source $dataFolder -destination $appPath
            Write-Host "Data moved back to the original location." -ForegroundColor Green

            Remove-Item -Path "$navigatorFolder\$($selectedApp.Name)" -Recurse -Force
            Write-Host "Configuration folder removed from 'navegator'." -ForegroundColor Green
        } else {
            Write-Host "No configuration found in 'navegator' for $($selectedApp.Name)." -ForegroundColor Yellow
        }

        if ($regPath -and (Test-Path $regPath)) {
            Remove-Item -Path $regPath -Recurse -Force
            Write-Host "Registry settings removed for $($selectedApp.Name)." -ForegroundColor Green
        }
    } else {
        Write-Host "Invalid option. The script will exit." -ForegroundColor Red
    }
} else {
    Write-Host "Invalid option. The script will exit." -ForegroundColor Red
}

Write-Host "Process completed! Press any key to exit." -ForegroundColor Green
[System.Console]::ReadKey($true) | Out-Null
Stop-Transcript
