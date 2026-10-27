<#
.SYNOPSIS
    Deploy CIS 3.0 Accelerator baseline policies and remediation scripts to Microsoft Intune.

.DESCRIPTION
    This script automates deployment of CIS benchmarks (Windows 11, Edge, Chrome, Office) to Intune
    via Microsoft Graph API. Features:
    - Interactive menu to select benchmark and tier (L1, L2, BL, NG)
    - Idempotent deployment (create if missing, update if changed, skip if identical)
    - Deploys both configuration policies and remediation scripts
    - Comprehensive logging and error handling

.PARAMETER WhatIf
    Simulates deployment without making changes to Intune tenant.

.EXAMPLE
    .\Deploy-CISBaseline.ps1
    Interactive deployment with menu selection.

.NOTES
    Author: Modern Workplace Team
    Requires: Microsoft.Graph.Authentication, Microsoft.Graph.DeviceManagement modules (v2.0+)
    Permissions: DeviceManagementConfiguration.ReadWrite.All
#>

[CmdletBinding(SupportsShouldProcess)]
param()

#Requires -Version 5.1
#Requires -Modules @{ ModuleName="Microsoft.Graph.Authentication"; ModuleVersion="2.0.0" }

# Global variables
$Global:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Global:ScriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$Global:LogLocation = Join-Path $Global:ScriptPath "Logs"
$Global:LogName = "Deploy-CISBaseline"
$Global:LogFilePath = $null
$Global:LogComponent = "Deploy-CIS"
$Global:UserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$Global:LogMaxSize = 250KB
$Global:CISAcceleratorPath = Join-Path (Split-Path -Parent $Global:ScriptPath) "CIS 3.0 Accelerator"

#region Functions

Function Write-Log {
    <#
    .SYNOPSIS
        Write CMTrace-compatible log entries.
    #>
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$ComponentName = $Global:LogComponent,

        [Parameter(Mandatory=$false)]
        [ValidateSet("1", "2", "3")]
        [Int]$Severity = 1
    )

    # Create log directory if it doesn't exist
    If (!(Test-Path -LiteralPath $Global:LogLocation)) {
        Try {
            New-Item -Path $Global:LogLocation -ItemType 'Directory' -Force | Out-Null
        }
        Catch {
            $ErrMsg = ("Log directory creation failed at line {0}: {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message)
            Write-Error -Message $ErrMsg -ErrorAction 'Stop'
        }
    }

    # Combine log location with log file
    If ([String]::IsNullOrWhitespace($Global:LogFilePath)) {
        $Global:LogFilePath = Join-Path $Global:LogLocation "$($Global:LogName).log"
    }

    # Create timestamp
    $LogTime = Get-Date -Format 'HH":"mm":"ss"."fffffff'
    $LogDate = Get-Date -Format 'MM-dd-yyyy'
    $LogContext = $Global:UserName

    # Construct CMTrace format
    $LogEntry = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="{7}">' -f `
        $Message, $LogTime, $LogDate, $ComponentName, $LogContext, $Severity, $PID, $Global:ScriptName

    # Write to log file
    Try {
        $LogEntry | Out-File -FilePath $Global:LogFilePath -Append -NoClobber -Force -Encoding 'Default' -ErrorAction 'Stop'
    }
    Catch {
        Write-Warning ("Failed to write log: {0}" -f $_.Exception.Message)
    }

    # Also write to console with color
    Switch ($Severity) {
        1 { Write-Host $Message -ForegroundColor White }
        2 { Write-Host $Message -ForegroundColor Yellow }
        3 { Write-Host $Message -ForegroundColor Red }
    }
}

Function Show-BenchmarkMenu {
    <#
    .SYNOPSIS
        Display interactive menu for selecting benchmark and tiers.
    .OUTPUTS
        Hashtable with Benchmark and Tiers keys
    #>

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "   CIS 3.0 Baseline Deployment Tool" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    # Benchmark selection
    Write-Host "Select Benchmark to Deploy:" -ForegroundColor Yellow
    Write-Host "[1] Windows 11 Intune v3.0.1"
    Write-Host "[2] Edge Enterprise v2.0.0"
    Write-Host "[3] Google Chrome Enterprise v3.0.0"
    Write-Host "[4] Office Intune v1.0.0"
    Write-Host "[5] All Benchmarks"
    Write-Host ""

    Do {
        $BenchmarkChoice = Read-Host "Enter selection (1-5)"
    } While ($BenchmarkChoice -notmatch '^[1-5]$')

    $BenchmarkMap = @{
        '1' = 'Windows 11 Intune v3.0.1'
        '2' = 'Edge Enterprise v2.0.0'
        '3' = 'Google Chrome Enterprise v3.0.0'
        '4' = 'Office Intune v1.0.0'
        '5' = 'All'
    }
    $SelectedBenchmark = $BenchmarkMap[$BenchmarkChoice]

    # Tier selection
    Write-Host "`nSelect Tier(s) to Deploy:" -ForegroundColor Yellow
    Write-Host "[1] L1 (Level 1) only"
    Write-Host "[2] L2 (Level 2) only"
    Write-Host "[3] BL (Baseline) only"
    Write-Host "[4] NG (Next Generation) only"
    Write-Host "[5] All Tiers"
    Write-Host "[6] L1 + L2"
    Write-Host ""

    Do {
        $TierChoice = Read-Host "Enter selection (1-6)"
    } While ($TierChoice -notmatch '^[1-6]$')

    $TierMap = @{
        '1' = @('L1')
        '2' = @('L2')
        '3' = @('BL')
        '4' = @('NG')
        '5' = @('L1', 'L2', 'BL', 'NG')
        '6' = @('L1', 'L2')
    }
    $SelectedTiers = $TierMap[$TierChoice]

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Selected Configuration:" -ForegroundColor Green
    Write-Host "  Benchmark: $SelectedBenchmark" -ForegroundColor White
    Write-Host "  Tiers: $($SelectedTiers -join ', ')" -ForegroundColor White
    Write-Host "========================================`n" -ForegroundColor Cyan

    $Confirmation = Read-Host "Proceed with deployment? (Y/N)"
    If ($Confirmation -ne 'Y') {
        Write-Host "Deployment cancelled by user." -ForegroundColor Yellow
        Exit 0
    }

    Return @{
        Benchmark = $SelectedBenchmark
        Tiers = $SelectedTiers
    }
}

Function Initialize-Environment {
    <#
    .SYNOPSIS
        Validate required modules and initialize environment.
    #>

    Write-Log "Initializing deployment environment..." -Severity 1

    # Check for required modules
    $RequiredModules = @(
        @{Name='Microsoft.Graph.Authentication'; MinVersion='2.0.0'},
        @{Name='Microsoft.Graph.DeviceManagement'; MinVersion='2.0.0'}
    )

    ForEach ($Module in $RequiredModules) {
        Write-Log "Checking for module: $($Module.Name) >= $($Module.MinVersion)" -Severity 1
        $InstalledModule = Get-Module -ListAvailable -Name $Module.Name |
            Where-Object { $_.Version -ge [Version]$Module.MinVersion } |
            Select-Object -First 1

        If (-not $InstalledModule) {
            Write-Log "Required module $($Module.Name) version $($Module.MinVersion) or higher not found." -Severity 3
            Write-Log "Install with: Install-Module -Name $($Module.Name) -MinimumVersion $($Module.MinVersion) -Scope CurrentUser" -Severity 2
            Throw "Missing required module: $($Module.Name)"
        }

        Write-Log "Module $($Module.Name) version $($InstalledModule.Version) found." -Severity 1
    }

    # Verify CIS Accelerator path exists
    If (!(Test-Path -Path $Global:CISAcceleratorPath)) {
        Write-Log "CIS Accelerator path not found: $Global:CISAcceleratorPath" -Severity 3
        Throw "CIS 3.0 Accelerator directory not found."
    }

    Write-Log "Environment initialization complete." -Severity 1
}

Function Connect-GraphAPI {
    <#
    .SYNOPSIS
        Authenticate to Microsoft Graph with required scopes.
    #>

    Write-Log "Connecting to Microsoft Graph..." -Severity 1

    Try {
        # Check if already connected
        $Context = Get-MgContext -ErrorAction SilentlyContinue

        If ($Context) {
            Write-Log "Already connected to Graph as: $($Context.Account)" -Severity 1

            # Verify required scopes
            $RequiredScopes = @('DeviceManagementConfiguration.ReadWrite.All')
            $MissingScopes = $RequiredScopes | Where-Object { $Context.Scopes -notcontains $_ }

            If ($MissingScopes) {
                Write-Log "Missing required scopes. Reconnecting..." -Severity 2
                Disconnect-MgGraph -ErrorAction SilentlyContinue
                Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' -NoWelcome -ErrorAction Stop
            }
        }
        Else {
            Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' -NoWelcome -ErrorAction Stop
        }

        $Context = Get-MgContext
        Write-Log "Successfully connected to tenant: $($Context.TenantId)" -Severity 1
        Write-Log "Authenticated as: $($Context.Account)" -Severity 1
    }
    Catch {
        Write-Log "Failed to connect to Microsoft Graph: $($_.Exception.Message)" -Severity 3
        Throw
    }
}

Function Get-PolicyTemplates {
    <#
    .SYNOPSIS
        Load CIS policy templates based on selected benchmark and tiers.
    .PARAMETER Benchmark
        Benchmark name or 'All'
    .PARAMETER Tiers
        Array of tier codes (L1, L2, BL, NG)
    #>

    Param(
        [Parameter(Mandatory=$true)]
        [String]$Benchmark,

        [Parameter(Mandatory=$true)]
        [String[]]$Tiers
    )

    Write-Log "Loading policy templates for: $Benchmark, Tiers: $($Tiers -join ',')" -Severity 1

    $PolicyTemplates = @()

    # Determine which benchmark folders to scan
    If ($Benchmark -eq 'All') {
        $BenchmarkFolders = Get-ChildItem -Path $Global:CISAcceleratorPath -Directory | Where-Object { $_.Name -match 'v\d+\.\d+' }
    }
    Else {
        $BenchmarkFolders = Get-ChildItem -Path $Global:CISAcceleratorPath -Directory | Where-Object { $_.Name -eq $Benchmark }
    }

    ForEach ($Folder in $BenchmarkFolders) {
        $TemplatesPath = Join-Path $Folder.FullName "Templates"

        If (!(Test-Path -Path $TemplatesPath)) {
            Write-Log "Templates folder not found: $TemplatesPath" -Severity 2
            Continue
        }

        # Get all JSON files
        $JsonFiles = Get-ChildItem -Path $TemplatesPath -Filter "*.json"

        ForEach ($JsonFile in $JsonFiles) {
            # Extract tier from filename (e.g., "CIS Windows 11 Intune Chapter 1 (L1).json")
            $FileTier = $null
            If ($JsonFile.Name -match '\(([A-Z0-9]+)\)\.json$') {
                $FileTier = $Matches[1]
            }

            # Check if this file matches selected tiers
            If ($FileTier -and $Tiers -contains $FileTier) {
                Try {
                    # Read JSON with UTF-16 LE encoding
                    $JsonContent = Get-Content -Path $JsonFile.FullName -Encoding Unicode -Raw -ErrorAction Stop
                    $PolicyObject = $JsonContent | ConvertFrom-Json -ErrorAction Stop

                    # Validate required fields
                    If (-not $PolicyObject.name -or -not $PolicyObject.'@odata.type') {
                        Write-Log "Invalid policy template (missing required fields): $($JsonFile.Name)" -Severity 2
                        Continue
                    }

                    $PolicyTemplates += [PSCustomObject]@{
                        Name = $PolicyObject.name
                        FilePath = $JsonFile.FullName
                        Benchmark = $Folder.Name
                        Tier = $FileTier
                        PolicyObject = $PolicyObject
                    }

                    Write-Log "Loaded template: $($PolicyObject.name)" -Severity 1
                }
                Catch {
                    Write-Log "Failed to load template $($JsonFile.Name): $($_.Exception.Message)" -Severity 3
                }
            }
        }
    }

    Write-Log "Loaded $($PolicyTemplates.Count) policy templates." -Severity 1
    Return $PolicyTemplates
}

Function Compare-PolicySettings {
    <#
    .SYNOPSIS
        Compare template policy with existing policy in Intune.
    .OUTPUTS
        String: "Create", "Update", or "Skip"
    #>

    Param(
        [Parameter(Mandatory=$true)]
        $TemplatePolicy,

        [Parameter(Mandatory=$false)]
        [String]$ExistingPolicyId
    )

    # If no existing policy, create new
    If ([String]::IsNullOrEmpty($ExistingPolicyId)) {
        Return "Create"
    }

    Try {
        # Get existing policy with settings
        $Uri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$ExistingPolicyId"
        $ExistingPolicy = Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop

        # Compare settings via hash
        $TemplateHash = ($TemplatePolicy.settings | ConvertTo-Json -Depth 100 -Compress | Get-FileHash -Algorithm SHA256).Hash
        $ExistingHash = ($ExistingPolicy.settings | ConvertTo-Json -Depth 100 -Compress | Get-FileHash -Algorithm SHA256).Hash

        If ($TemplateHash -eq $ExistingHash) {
            Return "Skip"
        }
        Else {
            Return "Update"
        }
    }
    Catch {
        Write-Log "Error comparing policy settings: $($_.Exception.Message)" -Severity 3
        Return "Create"
    }
}

Function Invoke-GraphRequestWithRetry {
    <#
    .SYNOPSIS
        Invoke Graph API request with retry logic for transient errors.
    #>

    Param(
        [Parameter(Mandatory=$true)]
        [String]$Method,

        [Parameter(Mandatory=$true)]
        [String]$Uri,

        [Parameter(Mandatory=$false)]
        $Body,

        [Parameter(Mandatory=$false)]
        [Int]$MaxRetries = 3
    )

    $RetryCount = 0
    $Success = $false
    $Response = $null

    While (-not $Success -and $RetryCount -lt $MaxRetries) {
        Try {
            If ($Body) {
                $Response = Invoke-MgGraphRequest -Method $Method -Uri $Uri -Body $Body -ErrorAction Stop
            }
            Else {
                $Response = Invoke-MgGraphRequest -Method $Method -Uri $Uri -ErrorAction Stop
            }
            $Success = $true
        }
        Catch {
            $StatusCode = $_.Exception.Response.StatusCode.value__

            # Retry on 429 (throttling) or 503 (service unavailable)
            If ($StatusCode -in @(429, 503) -and $RetryCount -lt ($MaxRetries - 1)) {
                $RetryCount++
                $WaitSeconds = [Math]::Pow(2, $RetryCount)
                Write-Log "Request failed with status $StatusCode. Retrying in $WaitSeconds seconds... (Attempt $RetryCount/$MaxRetries)" -Severity 2
                Start-Sleep -Seconds $WaitSeconds
            }
            Else {
                Throw
            }
        }
    }

    Return $Response
}

Function Deploy-Policy {
    <#
    .SYNOPSIS
        Deploy or update a configuration policy.
    #>

    Param(
        [Parameter(Mandatory=$true)]
        $TemplatePolicy,

        [Parameter(Mandatory=$true)]
        [String]$Action
    )

    $PolicyName = $TemplatePolicy.name

    Try {
        Switch ($Action) {
            "Create" {
                Write-Log "Creating policy: $PolicyName" -Severity 1

                If ($PSCmdlet.ShouldProcess($PolicyName, "Create policy")) {
                    $Uri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies"
                    $Response = Invoke-GraphRequestWithRetry -Method POST -Uri $Uri -Body ($TemplatePolicy | ConvertTo-Json -Depth 100)

                    Write-Log "Successfully created policy: $PolicyName (ID: $($Response.id))" -Severity 1
                    Return $Response.id
                }
            }

            "Update" {
                # Get existing policy ID
                $FilterUri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '$PolicyName'"
                $ExistingPolicies = Invoke-GraphRequestWithRetry -Method GET -Uri $FilterUri

                If ($ExistingPolicies.value.Count -gt 0) {
                    $ExistingId = $ExistingPolicies.value[0].id
                    Write-Log "Updating policy: $PolicyName (ID: $ExistingId)" -Severity 1

                    If ($PSCmdlet.ShouldProcess($PolicyName, "Update policy")) {
                        $Uri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$ExistingId"
                        $UpdateBody = @{
                            settings = $TemplatePolicy.settings
                            description = $TemplatePolicy.description
                        }

                        Invoke-GraphRequestWithRetry -Method PATCH -Uri $Uri -Body ($UpdateBody | ConvertTo-Json -Depth 100)
                        Write-Log "Successfully updated policy: $PolicyName" -Severity 1
                        Return $ExistingId
                    }
                }
            }

            "Skip" {
                Write-Log "Policy unchanged, skipping: $PolicyName" -Severity 1

                # Get existing policy ID for tracking
                $FilterUri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '$PolicyName'"
                $ExistingPolicies = Invoke-GraphRequestWithRetry -Method GET -Uri $FilterUri

                If ($ExistingPolicies.value.Count -gt 0) {
                    Return $ExistingPolicies.value[0].id
                }
            }
        }
    }
    Catch {
        Write-Log "Failed to $Action policy $PolicyName : $($_.Exception.Message)" -Severity 3
        Throw
    }
}

Function Get-RemediationScripts {
    <#
    .SYNOPSIS
        Get remediation scripts matching selected benchmark and tiers.
    #>

    Param(
        [Parameter(Mandatory=$true)]
        [String]$Benchmark,

        [Parameter(Mandatory=$true)]
        [String[]]$Tiers
    )

    Write-Log "Loading remediation scripts for: $Benchmark, Tiers: $($Tiers -join ',')" -Severity 1

    $RemediationScripts = @()

    # Determine which benchmark folders to scan
    If ($Benchmark -eq 'All') {
        $BenchmarkFolders = Get-ChildItem -Path $Global:CISAcceleratorPath -Directory | Where-Object { $_.Name -match 'v\d+\.\d+' }
    }
    Else {
        $BenchmarkFolders = Get-ChildItem -Path $Global:CISAcceleratorPath -Directory | Where-Object { $_.Name -eq $Benchmark }
    }

    ForEach ($Folder in $BenchmarkFolders) {
        $CodePath = Join-Path $Folder.FullName "Code"

        If (!(Test-Path -Path $CodePath)) {
            Continue
        }

        # Get PS1 files
        $ScriptFiles = Get-ChildItem -Path $CodePath -Filter "*.PS1"

        ForEach ($ScriptFile in $ScriptFiles) {
            # Extract tier from filename (e.g., "CIS L1 Remediation.PS1" or "CIS Edge L2 Remediation.PS1")
            $ScriptTier = $null
            If ($ScriptFile.Name -match '\b(L1|L2|BL|NG)\b') {
                $ScriptTier = $Matches[1]
            }

            # Check if this script matches selected tiers
            If ($ScriptTier -and $Tiers -contains $ScriptTier) {
                $RemediationScripts += [PSCustomObject]@{
                    Name = $ScriptFile.BaseName
                    FilePath = $ScriptFile.FullName
                    Benchmark = $Folder.Name
                    Tier = $ScriptTier
                }

                Write-Log "Found remediation script: $($ScriptFile.Name)" -Severity 1
            }
        }
    }

    Write-Log "Found $($RemediationScripts.Count) remediation scripts." -Severity 1
    Return $RemediationScripts
}

Function Deploy-RemediationScript {
    <#
    .SYNOPSIS
        Deploy a proactive remediation script to Intune.
    #>

    Param(
        [Parameter(Mandatory=$true)]
        $RemediationScript
    )

    $ScriptName = $RemediationScript.Name

    Try {
        Write-Log "Deploying remediation script: $ScriptName" -Severity 1

        # Read remediation script content
        $RemediationContent = Get-Content -Path $RemediationScript.FilePath -Raw -Encoding UTF8
        $RemediationBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($RemediationContent))

        # Create minimal detection script (always returns 1 to force remediation)
        $DetectionContent = @"
# Auto-generated detection script for CIS remediation
# Always returns exit code 1 to trigger remediation
Exit 1
"@
        $DetectionBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($DetectionContent))

        # Check if script already exists
        $FilterUri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts?`$filter=displayName eq '$ScriptName'"
        $ExistingScripts = Invoke-GraphRequestWithRetry -Method GET -Uri $FilterUri

        If ($ExistingScripts.value.Count -gt 0) {
            Write-Log "Remediation script already exists: $ScriptName (Skipping)" -Severity 2
            Return $ExistingScripts.value[0].id
        }

        If ($PSCmdlet.ShouldProcess($ScriptName, "Deploy remediation script")) {
            # Create deviceHealthScript
            $Body = @{
                displayName = $ScriptName
                description = "CIS $($RemediationScript.Benchmark) $($RemediationScript.Tier) Remediation"
                publisher = "CIS Benchmarks"
                runAsAccount = "system"
                enforceSignatureCheck = $false
                runAs32Bit = $false
                detectionScriptContent = $DetectionBase64
                remediationScriptContent = $RemediationBase64
            }

            $Uri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
            $Response = Invoke-GraphRequestWithRetry -Method POST -Uri $Uri -Body ($Body | ConvertTo-Json -Depth 10)

            Write-Log "Successfully deployed remediation script: $ScriptName (ID: $($Response.id))" -Severity 1
            Return $Response.id
        }
    }
    Catch {
        Write-Log "Failed to deploy remediation script $ScriptName : $($_.Exception.Message)" -Severity 3
        Throw
    }
}

#endregion Functions

#region Main Execution

Try {
    Write-Host "`n"
    Write-Log "===== CIS 3.0 Baseline Deployment Started =====" -Severity 1
    Write-Log "Script Version: 1.0" -Severity 1
    Write-Log "Execution Time: $(Get-Date)" -Severity 1

    # Initialize environment
    Initialize-Environment

    # Show menu and get selections
    $Selection = Show-BenchmarkMenu

    # Connect to Graph API
    Connect-GraphAPI

    # Load policy templates
    $PolicyTemplates = Get-PolicyTemplates -Benchmark $Selection.Benchmark -Tiers $Selection.Tiers

    If ($PolicyTemplates.Count -eq 0) {
        Write-Log "No policy templates found matching selection." -Severity 2
        Exit 0
    }

    # Deploy policies
    Write-Log "`n===== Deploying Configuration Policies =====" -Severity 1
    $DeploymentResults = @()

    ForEach ($Template in $PolicyTemplates) {
        Try {
            # Check if policy exists
            $FilterUri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '$($Template.Name)'"
            $ExistingPolicies = Invoke-GraphRequestWithRetry -Method GET -Uri $FilterUri

            $ExistingId = $null
            If ($ExistingPolicies.value.Count -gt 0) {
                $ExistingId = $ExistingPolicies.value[0].id
            }

            # Determine action
            $Action = Compare-PolicySettings -TemplatePolicy $Template.PolicyObject -ExistingPolicyId $ExistingId

            # Deploy
            $PolicyId = Deploy-Policy -TemplatePolicy $Template.PolicyObject -Action $Action

            $DeploymentResults += [PSCustomObject]@{
                PolicyName = $Template.Name
                Benchmark = $Template.Benchmark
                Tier = $Template.Tier
                Action = $Action
                PolicyID = $PolicyId
                Status = "Success"
            }
        }
        Catch {
            Write-Log "Error deploying policy $($Template.Name): $($_.Exception.Message)" -Severity 3

            $DeploymentResults += [PSCustomObject]@{
                PolicyName = $Template.Name
                Benchmark = $Template.Benchmark
                Tier = $Template.Tier
                Action = $Action
                PolicyID = $null
                Status = "Failed: $($_.Exception.Message)"
            }
        }
    }

    # Load and deploy remediation scripts
    Write-Log "`n===== Deploying Remediation Scripts =====" -Severity 1
    $RemediationScripts = Get-RemediationScripts -Benchmark $Selection.Benchmark -Tiers $Selection.Tiers

    ForEach ($Script in $RemediationScripts) {
        Try {
            $ScriptId = Deploy-RemediationScript -RemediationScript $Script

            $DeploymentResults += [PSCustomObject]@{
                PolicyName = $Script.Name
                Benchmark = $Script.Benchmark
                Tier = $Script.Tier
                Action = "Create"
                PolicyID = $ScriptId
                Status = "Success (Remediation Script)"
            }
        }
        Catch {
            Write-Log "Error deploying remediation script $($Script.Name): $($_.Exception.Message)" -Severity 3

            $DeploymentResults += [PSCustomObject]@{
                PolicyName = $Script.Name
                Benchmark = $Script.Benchmark
                Tier = $Script.Tier
                Action = "Create"
                PolicyID = $null
                Status = "Failed: $($_.Exception.Message)"
            }
        }
    }

    # Export summary
    $SummaryPath = Join-Path $Global:LogLocation "CIS-Deployment-Summary-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    $DeploymentResults | Export-Csv -Path $SummaryPath -NoTypeInformation -Encoding UTF8

    Write-Log "`n===== Deployment Summary =====" -Severity 1
    Write-Log "Total Items: $($DeploymentResults.Count)" -Severity 1
    Write-Log "Created: $(($DeploymentResults | Where-Object {$_.Action -eq 'Create'}).Count)" -Severity 1
    Write-Log "Updated: $(($DeploymentResults | Where-Object {$_.Action -eq 'Update'}).Count)" -Severity 1
    Write-Log "Skipped: $(($DeploymentResults | Where-Object {$_.Action -eq 'Skip'}).Count)" -Severity 1
    Write-Log "Failed: $(($DeploymentResults | Where-Object {$_.Status -like 'Failed*'}).Count)" -Severity 3
    Write-Log "Summary exported to: $SummaryPath" -Severity 1

    Write-Log "`n===== CIS 3.0 Baseline Deployment Completed =====" -Severity 1
}
Catch {
    Write-Log "Critical error during deployment: $($_.Exception.Message)" -Severity 3
    Write-Log "Stack Trace: $($_.Exception.StackTrace)" -Severity 3
    Exit 1
}

#endregion Main Execution
