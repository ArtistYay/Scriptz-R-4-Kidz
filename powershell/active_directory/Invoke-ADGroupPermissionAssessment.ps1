Import-Module ActiveDirectory

$OutputRoot = "C:\BODi_Discovery"
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

$staleDate = (Get-Date).AddDays(-90)

# Turns "CN=Domain Admins,OU=Groups,DC=corp,DC=local" into "Domain Admins"
function Get-GroupNameFromDN {
    param ([string]$DistinguishedName)
    ($DistinguishedName -split ',')[0] -replace 'CN='
}

# --- STALE ACCOUNTS (enabled, no logon in 90+ days or never) ---
Get-ADUser -Filter {Enabled -eq $true} -Properties LastLogonDate, Description,
    Department, Title, Manager, whenCreated |
    Where-Object { $_.LastLogonDate -lt $staleDate -or $_.LastLogonDate -eq $null } |
    Select-Object SamAccountName, Name, Title, Department, Description,
    LastLogonDate, whenCreated,
    @{N='DaysSinceLogon';E={if($_.LastLogonDate){((Get-Date) - $_.LastLogonDate).Days}else{'Never'}}},
    @{N='RiskLevel';E={
        if(-not $_.LastLogonDate){'HIGH - Never logged in'}
        elseif(((Get-Date) - $_.LastLogonDate).Days -gt 180){'HIGH - 180+ days'}
        else{'MEDIUM - 90-180 days'}
    }} |
    Sort-Object LastLogonDate |
    Export-Csv -Path "$OutputRoot\AD_Users_Stale.csv" -NoTypeInformation

# --- OVER-PRIVILEGED USERS (members of high-priv groups) ---
$privilegedGroups = @(
    "Domain Admins", "Enterprise Admins", "Schema Admins",
    "Administrators", "Account Operators", "Server Operators",
    "Backup Operators", "Print Operators", "DnsAdmins",
    "Group Policy Creator Owners"
)

$privilegedUsers = foreach ($group in $privilegedGroups) {
    try {
        Get-ADGroupMember -Identity $group -Recursive -ErrorAction SilentlyContinue | ForEach-Object {
            $user = $null
            if ($_.objectClass -eq 'user') {
                $user = Get-ADUser -Identity $_.SamAccountName -Properties LastLogonDate, Title, Enabled -ErrorAction SilentlyContinue
            }
            [PSCustomObject]@{
                Account       = $_.SamAccountName
                Name          = $_.Name
                PrivGroup     = $group
                ObjectType    = $_.objectClass
                Enabled       = if($user){$user.Enabled}else{$null}
                LastLogon     = if($user){$user.LastLogonDate}else{$null}
                Title         = if($user){$user.Title}else{$null}
                RiskNote      = if(-not $user){"Review - Non-user object in admin group"}
                               elseif(-not $user.Enabled){"CRITICAL - Disabled but still in admin group"}
                               elseif($user.LastLogonDate -lt $staleDate){"HIGH - Stale admin account"}
                               else{"Review - Active admin"}
            }
        }
    } catch {
        Write-Warning "Could not enumerate group: $group"
    }
}
$privilegedUsers | Export-Csv -Path "$OutputRoot\AD_Users_OverPrivileged.csv" -NoTypeInformation

# --- ORPHANED ACCOUNTS (disabled but still in groups) ---
Get-ADUser -Filter {Enabled -eq $false} -Properties MemberOf, LastLogonDate, Description |
    Where-Object { $_.MemberOf.Count -gt 1 } |
    Select-Object SamAccountName, Name, Description, LastLogonDate,
    @{N='GroupCount';E={$_.MemberOf.Count}},
    @{N='Groups';E={($_.MemberOf | ForEach-Object { Get-GroupNameFromDN $_ }) -join '; '}},
    @{N='Risk';E={
        $groupNames = ($_.MemberOf | ForEach-Object { Get-GroupNameFromDN $_ })
        if($groupNames | Where-Object { $_ -in $privilegedGroups }){"CRITICAL - Disabled with admin access"}
        else{"MEDIUM - Disabled with residual access"}
    }} |
    Export-Csv -Path "$OutputRoot\AD_Users_Orphaned.csv" -NoTypeInformation

# --- GROUP STRUCTURE (for context) ---
Get-ADGroup -Filter * -Properties Description, Members, MemberOf, GroupCategory, GroupScope, whenCreated |
    Select-Object Name, GroupCategory, GroupScope, Description,
    @{N='MemberCount';E={$_.Members.Count}},
    @{N='NestedInGroups';E={$_.MemberOf.Count}},
    @{N='IsEmpty';E={$_.Members.Count -eq 0}},
    whenCreated |
    Export-Csv -Path "$OutputRoot\AD_Groups_All.csv" -NoTypeInformation

Get-ADGroup -Filter * -Properties Members |
    Where-Object { $_.Members.Count -eq 0 } |
    Select-Object Name, GroupCategory, GroupScope |
    Export-Csv -Path "$OutputRoot\AD_Groups_Empty.csv" -NoTypeInformation

Write-Host "AD permissions assessment complete. Outputs:"
Get-ChildItem $OutputRoot -Filter "AD_*.csv" | Select-Object Name, Length
