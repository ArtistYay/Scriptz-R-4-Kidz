# ============================================================
# Offline Domain Controller Retirement Assessmentv6.1
#
# Any enhancements MUST:
# - Be approved by ?
# - Be documented in the README
# ============================================================

# ----------------------------
# Phase 0: Configuration
# ----------------------------
Write-Host "$(Get-Date -Format 'HH:mm:ss') - Phase 0: Initializing configuration..."

$InputDir = "C:\InputCSV"

$RunDate    = Get-Date -Format "MMddyyyy"
$BaseOutDir = Join-Path $InputDir "Outputs"
$OutDir     = Join-Path $BaseOutDir $RunDate
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$EventFiles = @{
    4768 = "Event_4768.csv"
    4769 = "Event_4769.csv"
    4770 = "Event_4770.csv"
    4771 = "Event_4771.csv"
    5156 = "Event_5156.csv"
    8004 = "Event_8004.csv"
}

$ADComputerCsv  = Join-Path $InputDir "AD_Computers.csv"
$SuppressionCsv = Join-Path $InputDir "KnownGood_Suppressions.csv"

# ----------------------------
# Phase 0a: Schema Assertion (Fail-Fast)
# ----------------------------
Write-Host "$(Get-Date -Format 'HH:mm:ss') - Phase 0a: Validating input CSV schemas..."

$ExpectedSchemas = @{
    "Event_4768.csv" = @("@timestamp","service.name","source.ip","user.name","winlog.event_data.ServiceSid")
    "Event_4769.csv" = @("@timestamp","service.name","source.ip","related.ip","user.name")
    "Event_4770.csv" = @("@timestamp","service.name","source.ip","related.ip","user.name")
    "Event_4771.csv" = @("@timestamp","service.name","source.ip","related.ip","user.name")
    "Event_5156.csv" = @("@timestamp","host.hostname","source.ip","destination.ip")
    "Event_8004.csv" = @("@timestamp","host.hostname","winlog.event_data.WorkstationName","winlog.user.name")
}

function Assert-InputSchema {
    param ([string]$FileName, [string[]]$RequiredColumns)

    $path = Join-Path $InputDir $FileName
    if (-not (Test-Path $path)) {
        throw "SCHEMA ERROR: Required input file missing: $FileName"
    }

    # PS 5.1–safe header read
    $headers = (
        Get-Content -Path $path -TotalCount 1 |
        ConvertFrom-Csv
    ).PSObject.Properties.Name

    $missing = $RequiredColumns | Where-Object { $headers -notcontains $_ }

    if ($missing.Count -gt 0) {
        Write-Error "SCHEMA VALIDATION FAILED for $FileName"
        Write-Error "Missing required columns:"
        $missing | ForEach-Object { Write-Error " - $_" }
        throw "Schema validation failure. Aborting execution."
    }

    Write-Host "$(Get-Date -Format 'HH:mm:ss') - Schema OK: $FileName"
}

foreach ($file in $ExpectedSchemas.Keys) {
    Assert-InputSchema -FileName $file -RequiredColumns $ExpectedSchemas[$file]
}

Write-Host "$(Get-Date -Format 'HH:mm:ss') - Phase 0a: Schema validation complete."

# ----------------------------
# Phase 1: Load AD Inventory
# ----------------------------
Write-Host "$(Get-Date -Format 'HH:mm:ss') - Phase 1: Loading AD computer inventory..."

if (-not (Test-Path $ADComputerCsv)) {
    throw "Missing AD inventory file: $ADComputerCsv"
}

$ADComputers = Import-Csv $ADComputerCsv
$AD_ByIP   = @{}
$AD_ByName = @{}

foreach ($Computer in $ADComputers) {
    if ($Computer.IPv4Address) { $AD_ByIP[$Computer.IPv4Address] = $Computer }
    if ($Computer.Name) { $AD_ByName[$Computer.Name.ToLower()] = $Computer }
}

# ----------------------------
# Phase 2: Load Known-Good Suppressions
# ----------------------------
Write-Host "$(Get-Date -Format 'HH:mm:ss') - Phase 2: Loading Known-Good suppressions..."

$Suppressions = @()
if (Test-Path $SuppressionCsv) {
    $Suppressions = Import-Csv $SuppressionCsv
}

# ----------------------------
# Phase 3: Helper Functions
# ----------------------------
Write-Host "$(Get-Date -Format 'HH:mm:ss') - Phase 3: Defining helper functions..."

function Get-Field {
    param ($Row, [string]$Name)
    if ($Row.PSObject.Properties.Name -contains $Name) {
        return $Row.$Name
    }
    return $null
}

# Returns the first column that has a value, e.g. 'source.ip' then 'related.ip'
function Get-FirstField {
    param ($Row, [string]$PrimaryName, [string]$FallbackName)
    $value = Get-Field $Row $PrimaryName
    if (-not $value) { $value = Get-Field $Row $FallbackName }
    return $value
}

function Resolve-ADComputerOffline {
    param ($ClientIP, $Account)

    if ($ClientIP -and $AD_ByIP.ContainsKey($ClientIP)) {
        return $AD_ByIP[$ClientIP]
    }

    if ($Account -and $Account.EndsWith('$')) {
        $ComputerName = $Account.TrimEnd('$').ToLower()
        if ($AD_ByName.ContainsKey($ComputerName)) { return $AD_ByName[$ComputerName] }
    }
    return $null
}

function Get-BlockerType {
    # Not named $Event: that is a PowerShell automatic variable.
    param ($EventRecord)

    switch ($EventRecord.EventID) {
        8004 { "NTLM_AUTH_BLOCKER" }
        4771 { "KERBEROS_PREAUTH_FAILURE" }
        4769 {
            if ($EventRecord.Service -match '_ldap|_kerberos|_msdcs') {
                "KERBEROS_SERVICE_DEPENDENCY"
            } else { "Observed" }
        }
        5156 { "NETWORK_PATH_DEPENDENCY" }
        default { "Observed" }
    }
}

function Test-KnownGoodSuppression {
    param ($Row, $Suppressions)

    foreach ($Suppression in $Suppressions) {
        $IsExpired = $false
        if ($Suppression.ExpiryDate -and ([datetime]$Suppression.ExpiryDate -lt (Get-Date))) {
            $IsExpired = $true
        }

        $IsMatch = $false
        switch ($Suppression.MatchType) {
            "ADComputerName" { $IsMatch = ($Row.ADComputerName -eq $Suppression.MatchValue) }
            "ClientIP"       { $IsMatch = ($Row.ClientIP -eq $Suppression.MatchValue) }
            "Account"        { $IsMatch = ($Row.Account -eq $Suppression.MatchValue) }
            "Service"        { $IsMatch = ($Row.Service -eq $Suppression.MatchValue) }
            "EventID"        { $IsMatch = ($Row.EventID -eq [int]$Suppression.MatchValue) }
            "BlockerType"    { $IsMatch = ($Row.BlockerType -eq $Suppression.MatchValue) }
        }

        if ($IsMatch) {
            return [PSCustomObject]@{
                MatchedRule = $Suppression
                IsExpired   = $IsExpired
            }
        }
    }
    return $null
}

function ConvertTo-NormalizedEvent {
    param ($Row, [int]$EventID)

    [PSCustomObject]@{
        EventID     = $EventID
        TimeCreated = Get-Field $Row '@timestamp'
        DC          = Get-FirstField $Row 'service.name' 'host.hostname'
        ClientIP    = Get-FirstField $Row 'source.ip' 'related.ip'
        Account     = Get-FirstField $Row 'user.name' 'winlog.user.name'
        Service     = Get-FirstField $Row 'service.name' 'winlog.event_data.ServiceSid'
        Destination = Get-FirstField $Row 'destination.ip' 'winlog.event_data.WorkstationName'
        Process     = $null
    }
}

function Get-RiskClass {
    param ($BlockerType, $ADComputer)

    $RiskClass = "LOW"
    if ($BlockerType -ne "Observed") {
        if ($ADComputer -and $ADComputer.OperatingSystem -match "Server") { $RiskClass = "HIGH" }
        else { $RiskClass = "MEDIUM" }
    }
    return $RiskClass
}

function New-EnrichedRow {
    param ($EventRecord, $ADComputer, $BlockerType)

    [PSCustomObject]@{
        TimeCreated       = $EventRecord.TimeCreated
        DC                = $EventRecord.DC
        ClientIP          = $EventRecord.ClientIP
        Account           = $EventRecord.Account
        EventID           = $EventRecord.EventID
        Service           = $EventRecord.Service
        Process           = $EventRecord.Process
        Destination       = $EventRecord.Destination

        ADComputerName    = if ($ADComputer) { $ADComputer.Name } else { "UNRESOLVED" }
        ADOperatingSystem = if ($ADComputer) { $ADComputer.OperatingSystem } else { $null }
        ADOU              = if ($ADComputer) { ($ADComputer.DistinguishedName -split ',',2)[1] } else { $null }

        BlockerType       = $BlockerType
        IsBlocker         = if ($BlockerType -ne "Observed") { "YES" } else { "NO" }
        RiskClass         = Get-RiskClass $BlockerType $ADComputer

        Suppressed        = "NO"
        SuppressionReason = $null
        ApprovedBy        = $null
        SuppressionExpiry = $null

        IsKnownGoodMatch  = "NO"
        KnownGoodStatus   = "NONE"

        SeenOnDCs         = $null
        SeenOnDCCount     = 0
    }
}

function Set-KnownGoodStatus {
    param ($Row, $Suppressions)

    $KnownGoodMatch = Test-KnownGoodSuppression $Row $Suppressions
    if ($KnownGoodMatch) {
        $Row.IsKnownGoodMatch = "YES"
        if (-not $KnownGoodMatch.IsExpired) {
            $Row.KnownGoodStatus   = "ACTIVE"
            $Row.Suppressed        = "YES"
            $Row.RiskClass         = "SUPPRESSED"
            $Row.SuppressionReason = $KnownGoodMatch.MatchedRule.Reason
            $Row.ApprovedBy        = $KnownGoodMatch.MatchedRule.ApprovedBy
            $Row.SuppressionExpiry = $KnownGoodMatch.MatchedRule.ExpiryDate
        } else {
            $Row.KnownGoodStatus = "EXPIRED"
        }
    }
}

function Get-CorrelationKey {
    param ($Row)
    "$($Row.ClientIP)|$($Row.Account)|$($Row.ADComputerName)"
}

# ----------------------------
# Phase 4: Load Events (Locked Schema)
# ----------------------------
Write-Host "$(Get-Date -Format 'HH:mm:ss') - Phase 4: Loading event CSV files..."

$AllEvents = New-Object System.Collections.Generic.List[object]

foreach ($EventID in $EventFiles.Keys) {
    $Path = Join-Path $InputDir $EventFiles[$EventID]
    if (-not (Test-Path $Path)) { continue }

    Write-Host "$(Get-Date -Format 'HH:mm:ss') - Phase 4: Processing $($EventFiles[$EventID])..."
    $RowCount = 0

    Import-Csv $Path | ForEach-Object {
        $AllEvents.Add((ConvertTo-NormalizedEvent -Row $_ -EventID $EventID))

        $RowCount++
        if ($RowCount % 100000 -eq 0) {
            Write-Host "$(Get-Date -Format 'HH:mm:ss') - Phase 4: Loaded $RowCount rows..."
        }
    }

    Write-Host "$(Get-Date -Format 'HH:mm:ss') - Phase 4: Completed $($EventFiles[$EventID]) ($RowCount rows)"
}

# ----------------------------
# Phase 5: Enrichment
# ----------------------------
Write-Host "$(Get-Date -Format 'HH:mm:ss') - Phase 5: Enriching events..."

$Enriched = $AllEvents | ForEach-Object {
    $ADComputer  = Resolve-ADComputerOffline $_.ClientIP $_.Account
    $BlockerType = Get-BlockerType $_

    $Row = New-EnrichedRow -EventRecord $_ -ADComputer $ADComputer -BlockerType $BlockerType
    Set-KnownGoodStatus -Row $Row -Suppressions $Suppressions
    $Row
}

# ----------------------------
# Phase 6: SeenOnDCs Correlation
# ----------------------------
Write-Host "$(Get-Date -Format 'HH:mm:ss') - Phase 6: Correlating DC visibility..."

$SeenMap = @{}
foreach ($EnrichedRow in $Enriched) {
    $key = Get-CorrelationKey $EnrichedRow
    if (-not $SeenMap.ContainsKey($key)) {
        $SeenMap[$key] = New-Object System.Collections.Generic.HashSet[string]
    }
    $SeenMap[$key].Add($EnrichedRow.DC) | Out-Null
}

foreach ($EnrichedRow in $Enriched) {
    $key = Get-CorrelationKey $EnrichedRow
    $EnrichedRow.SeenOnDCs     = ($SeenMap[$key] -join '; ')
    $EnrichedRow.SeenOnDCCount = $SeenMap[$key].Count
}

# ----------------------------
# Phase 7: Outputs
# ----------------------------
Write-Host "$(Get-Date -Format 'HH:mm:ss') - Phase 7: Writing outputs..."

$Enriched | Export-Csv "$OutDir\DC_Retirement_Assessment.csv" -NoTypeInformation

$Enriched |
Where-Object { $_.IsBlocker -eq "YES" -and $_.Suppressed -eq "NO" } |
Export-Csv "$OutDir\DC_Retirement_Blockers.csv" -NoTypeInformation

$Enriched |
Group-Object DC |
ForEach-Object {
    $Blockers = $_.Group | Where-Object { $_.IsBlocker -eq "YES" -and $_.Suppressed -eq "NO" }
    [PSCustomObject]@{
        DC              = $_.Name
        EventsObserved  = $_.Count
        BlockerCount    = $Blockers.Count
        RetirementReady = if ($Blockers.Count -eq 0) { "YES" } else { "NO" }
    }
} | Export-Csv "$OutDir\DC_Readiness_Summary.csv" -NoTypeInformation

Write-Host "$(Get-Date -Format 'HH:mm:ss') - Offline Domain Controller Retirement Assessment complete."
