<#
.SYNOPSIS
    Updates all winget packages once a month, the first time you sign in that month.

.DESCRIPTION
    Run this once with -Register (as Administrator) to install a scheduled task.
    After that, the task runs this script every time you sign in, and the script
    only does the work if it hasn't already run this calendar month. So the
    update happens on the 1st if the computer is on, or at the next sign-in
    after the 1st if it isn't. A missed month is never skipped.

    Each monthly run:
      1. winget source update   (refreshes the package list)
      2. winget upgrade --all   (upgrades everything that has a newer version)

    Logs: %LOCALAPPDATA%\WingetMonthlyUpdate\winget-update-<yyyy-MM>.log

.PARAMETER Register
    Copies this script to C:\Program Files\WingetMonthlyUpdate and creates the
    scheduled task for the current user. Needs Administrator.

.PARAMETER Unregister
    Removes the scheduled task and the installed copy. Logs are kept.
    Needs Administrator.

.PARAMETER Force
    Runs the update now, even if it already ran this month.

.EXAMPLE
    .\Update-WingetPackages.ps1 -Register
    Installs the monthly task. Run from an Administrator PowerShell.

.EXAMPLE
    .\Update-WingetPackages.ps1 -Force -WhatIf
    Shows what would run without upgrading anything.

.NOTES
    Exclude a package from upgrades with: winget pin add --id <PackageId>
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Run')]
param(
    [Parameter(ParameterSetName = 'Register')]
    [switch]$Register,

    [Parameter(ParameterSetName = 'Unregister')]
    [switch]$Unregister,

    [Parameter(ParameterSetName = 'Run')]
    [switch]$Force
)

#Requires -Version 5.1

$TaskName        = 'Winget Monthly Update'
# Program Files is admin-write only, so a non-admin process can't swap out
# the script that the task runs with elevated rights.
$InstallDir      = Join-Path $env:ProgramFiles 'WingetMonthlyUpdate'
$InstalledScript = Join-Path $InstallDir 'Update-WingetPackages.ps1'
$StateDir        = Join-Path $env:LOCALAPPDATA 'WingetMonthlyUpdate'
$StateFile       = Join-Path $StateDir 'last-run.txt'
$CurrentMonth    = Get-Date -Format 'yyyy-MM'
$LogFile         = Join-Path $StateDir "winget-update-$CurrentMonth.log"
$LogsToKeep      = 12

function Write-Log {
    param ([string]$Message)

    $line = "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Host $line
    # -WhatIf:$false so the log is still written during a -WhatIf dry run.
    Add-Content -Path $LogFile -Value $line -WhatIf:$false
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-AlreadyRanThisMonth {
    if (-not (Test-Path $StateFile)) { return $false }
    return (Get-Content -Path $StateFile -TotalCount 1) -eq $CurrentMonth
}

function Invoke-Winget {
    [CmdletBinding(SupportsShouldProcess)]
    param ([string]$WingetPath, [string[]]$Arguments)

    $commandLine = "winget $($Arguments -join ' ')"
    Write-Log "Running: $commandLine"

    if (-not $PSCmdlet.ShouldProcess($commandLine, 'Run')) { return 0 }

    & $WingetPath @Arguments 2>&1 |
        ForEach-Object { "$_".Trim() } |
        Where-Object { $_ } |
        ForEach-Object { Write-Log "  $_" }
    return $LASTEXITCODE
}

function Save-RunMonth {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    if ($PSCmdlet.ShouldProcess($StateFile, "Mark $CurrentMonth as done")) {
        Set-Content -Path $StateFile -Value $CurrentMonth
    }
}

function Remove-OldLogs {
    Get-ChildItem -Path $StateDir -Filter 'winget-update-*.log' |
        Sort-Object Name -Descending |
        Select-Object -Skip $LogsToKeep |
        Remove-Item -Force
}

function Invoke-MonthlyUpdate {
    [CmdletBinding(SupportsShouldProcess)]
    param ([switch]$Force)

    New-Item -ItemType Directory -Path $StateDir -Force -WhatIf:$false | Out-Null

    # Runs at every sign-in, so exit quietly when this month is already done.
    if (-not $Force -and (Test-AlreadyRanThisMonth)) { return }

    Write-Log "===== Monthly winget update started ($CurrentMonth) ====="

    $wingetPath = (Get-Command winget.exe -ErrorAction SilentlyContinue).Source
    if (-not $wingetPath) {
        Write-Log "winget was not found. Install 'App Installer' from the Microsoft Store. Will try again at next sign-in."
        exit 1
    }

    $sourceExitCode = Invoke-Winget -WingetPath $wingetPath -Arguments @(
        'source', 'update', '--disable-interactivity'
    )
    if ($sourceExitCode -ne 0) {
        # Usually no network yet. Not marked as done, so it retries next sign-in.
        Write-Log ("Source update failed (exit code 0x{0:X8}). Will try again at next sign-in." -f $sourceExitCode)
        exit 1
    }

    $upgradeExitCode = Invoke-Winget -WingetPath $wingetPath -Arguments @(
        'upgrade', '--all', '--silent',
        '--accept-package-agreements', '--accept-source-agreements',
        '--disable-interactivity'
    )
    if ($upgradeExitCode -eq 0) {
        Write-Log "All upgrades finished."
    }
    else {
        # Still marked as done: one app that always fails shouldn't re-run
        # the whole upgrade at every sign-in. Check the log for which one.
        Write-Log ("Some upgrades failed (exit code 0x{0:X8}). See the lines above." -f $upgradeExitCode)
    }

    Save-RunMonth
    Remove-OldLogs
    Write-Log "===== Monthly winget update finished ====="
}

function Register-UpdateTask {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    if (-not (Test-IsAdministrator)) {
        throw "Run PowerShell as Administrator to use -Register."
    }

    if ($PSCmdlet.ShouldProcess($InstalledScript, 'Install script')) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        if ($PSCommandPath -ne $InstalledScript) {
            Copy-Item -Path $PSCommandPath -Destination $InstalledScript -Force
        }
        # Downloaded files are marked as from the internet, and RemoteSigned
        # would refuse to run them. You chose to install this one.
        Unblock-File -Path $InstalledScript
    }

    $userName = [Security.Principal.WindowsIdentity]::GetCurrent().Name

    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument (
        "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy RemoteSigned -File `"$InstalledScript`""
    )
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $userName
    $trigger.Delay = 'PT2M'  # give Wi-Fi a couple of minutes to connect
    # Highest = elevated, so machine-wide apps can upgrade without a UAC prompt.
    $principal = New-ScheduledTaskPrincipal -UserId $userName -LogonType Interactive -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -MultipleInstances IgnoreNew `
        -ExecutionTimeLimit (New-TimeSpan -Hours 2)

    if ($PSCmdlet.ShouldProcess($TaskName, "Register scheduled task for $userName")) {
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
            -Principal $principal -Settings $settings -Force `
            -Description 'Runs winget upgrade --all at the first sign-in of each month.' | Out-Null
        Write-Host "Registered '$TaskName' for $userName. It runs at your first sign-in each month."
        Write-Host "Logs: $StateDir"
    }
}

function Unregister-UpdateTask {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    if (-not (Test-IsAdministrator)) {
        throw "Run PowerShell as Administrator to use -Unregister."
    }

    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess($TaskName, 'Remove scheduled task')) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }
    }
    if (Test-Path $InstallDir) {
        if ($PSCmdlet.ShouldProcess($InstallDir, 'Remove installed script')) {
            Remove-Item -Path $InstallDir -Recurse -Force
        }
    }
    Write-Host "Removed '$TaskName'. Logs are still in $StateDir"
}

switch ($PSCmdlet.ParameterSetName) {
    'Register'   { Register-UpdateTask }
    'Unregister' { Unregister-UpdateTask }
    default      { Invoke-MonthlyUpdate -Force:$Force }
}
