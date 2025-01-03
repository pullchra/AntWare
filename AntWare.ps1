Function Check-Administrator {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Administrator permission required. Rerunning the script with elevated privileges..." -ForegroundColor Yellow
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    }
}

Check-Administrator

Start-Transcript -Path "$env:TEMP\script-log.txt" -Append
Write-Host "Starting the script..." -ForegroundColor Green

$ErrorActionPreference = "Stop"

Function Check-Installation {
    param(
        [string]$appName,
        [string]$installPath
    )

    if (Test-Path $installPath) {
        Write-Host "$appName is installed." -ForegroundColor Cyan
        return $true
    } else {
        Write-Host "$appName is not installed. Please make sure it is properly installed on your system." -ForegroundColor Yellow
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
        Write-Host "Source folder '$source' not found. No action will be performed." -ForegroundColor Yellow
    }
}

Function Configure-BrowserOrApp {
    param(
        [string]$appName,
        [string]$installPath,
        [string]$subFolder,
        [string]$regKeyPath,
        [string]$oldFolder
    )

    if (Check-Installation -appName $appName -installPath $installPath) {
        $appSubFolder = Join-Path -Path $navigatorFolder -ChildPath $subFolder
        if (-not (Test-Path $appSubFolder)) {
            New-Item -Path $appSubFolder -ItemType Directory -Force
            Write-Host "Subfolder '$subFolder' created at: $appSubFolder" -ForegroundColor Green
        }

        Copy-Data -source $oldFolder -destination $appSubFolder

        if (-not (Test-Path $regKeyPath)) {
            Write-Host "Creating registry key: $regKeyPath" -ForegroundColor Yellow
            New-Item -Path $regKeyPath -Force
        }

        Set-ItemProperty -Path $regKeyPath -Name "UserDataDir" -Value $appSubFolder
        Set-ItemProperty -Path $regKeyPath -Name "ForceUserDataDir" -Value 1
        Write-Host "$appName configured to use folder: $appSubFolder" -ForegroundColor Green
    }
}

Function Revert-Configurations {
    param(
        [string]$appName,
        [string]$regKeyPath,
        [string]$subFolder
    )

    $appFolder = Join-Path -Path $navigatorFolder -ChildPath $subFolder
    if (Test-Path $appFolder) {
        Remove-Item -Path $appFolder -Recurse -Force
        Write-Host "Folder '$subFolder' removed successfully." -ForegroundColor Green
    } else {
        Write-Host "Folder '$subFolder' not found. No action will be performed." -ForegroundColor Yellow
    }

    if (Test-Path $regKeyPath) {
        Remove-Item -Path $regKeyPath -Recurse -Force
        Write-Host "Registry configuration removed for '$appName'." -ForegroundColor Green
    } else {
        Write-Host "Registry key for '$appName' not found." -ForegroundColor Yellow
    }
}

$chosenDirectory = Read-Host "Enter the full path where the 'navigator' folder is located (example: C:\Test\) "
$navigatorFolder = Join-Path -Path $chosenDirectory -ChildPath "navigator"

if (-not (Test-Path $navigatorFolder)) {
    Write-Host "The 'navigator' folder was not found in the specified directory. The script will be terminated." -ForegroundColor Red
    Exit
}

$options = @(
    @{Name = "Edge"; InstallPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"; SubFolder = "Edge"; RegKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; OldFolder = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"},
    @{Name = "Chrome"; InstallPath = "C:\Program Files\Google\Chrome\Application\chrome.exe"; SubFolder = "Chrome"; RegKeyPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"; OldFolder = "$env:LOCALAPPDATA\Google\Chrome\User Data"},
    @{Name = "Brave"; InstallPath = "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"; SubFolder = "Brave"; RegKeyPath = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave-Browser"; OldFolder = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"},
    @{Name = "Opera"; InstallPath = "C:\Program Files\Opera\opera.exe"; SubFolder = "Opera"; RegKeyPath = "HKLM:\SOFTWARE\Policies\Opera Software\Opera"; OldFolder = "$env:LOCALAPPDATA\Opera Software\Opera Stable"},
    @{Name = "Discord"; InstallPath = "C:\Users\$env:USERNAME\AppData\Local\Discord\app-*.exe"; SubFolder = "Discord"; RegKeyPath = "HKCU:\Software\Discord"; OldFolder = "$env:APPDATA\discord"}
)

Write-Host "Choose an option:"
for ($i = 0; $i -lt $options.Length; $i++) {
    Write-Host "$($i + 1) - $($options[$i].Name)"
}

$choice = Read-Host "Enter the number of the desired option"

if ($choice -ge 1 -and $choice -le $options.Length) {
    $chosenApp = $options[$choice - 1]
    $action = Read-Host "Enter 'C' to configure or 'R' to revert the settings"
    
    if ($action -ieq "C") {
        Configure-BrowserOrApp -appName $chosenApp.Name -installPath $chosenApp.InstallPath -subFolder $chosenApp.SubFolder -regKeyPath $chosenApp.RegKeyPath -oldFolder $chosenApp.OldFolder
    } elseif ($action -ieq "R") {
        Revert-Configurations -appName $chosenApp.Name -regKeyPath $chosenApp.RegKeyPath -subFolder $chosenApp.SubFolder
    } else {
        Write-Host "Invalid option. The script will be terminated." -ForegroundColor Red
    }
} else {
    Write-Host "Invalid option. The script will be terminated." -ForegroundColor Red
}

Write-Host "Process completed! Press any key to exit." -ForegroundColor Green
[System.Console]::ReadKey($true) | Out-Null
Stop-Transcript
