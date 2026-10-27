Import-Module ActiveDirectory

$OutputRoot = "C:\Discovery"
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

# --- All DCs with details ---
$domainControllers = Get-ADDomainController -Filter * | Select-Object `
    Name,
    IPv4Address,
    OperatingSystem,
    OperatingSystemVersion,
    Site,
    IsGlobalCatalog,
    IsReadOnly,
    Enabled

$domainControllers | Export-Csv -Path "$OutputRoot\AD_DomainControllers.csv" -NoTypeInformation

# --- FSMO Role Holders ---
$forest = Get-ADForest
$domain = Get-ADDomain

[PSCustomObject]@{
    SchemaMaster          = $forest.SchemaMaster
    DomainNamingMaster    = $forest.DomainNamingMaster
    PDCEmulator           = $domain.PDCEmulator
    RIDMaster             = $domain.RIDMaster
    InfrastructureMaster  = $domain.InfrastructureMaster
    ForestFunctionalLevel = $forest.ForestMode
    DomainFunctionalLevel = $domain.DomainMode
} | Export-Csv -Path "$OutputRoot\AD_FSMO_Roles.csv" -NoTypeInformation

# --- AD Sites & Subnets ---
Get-ADReplicationSite -Filter * | Select-Object Name, Description |
    Export-Csv -Path "$OutputRoot\AD_Sites.csv" -NoTypeInformation

Get-ADReplicationSubnet -Filter * | Select-Object Name, Site, Location |
    Export-Csv -Path "$OutputRoot\AD_Subnets.csv" -NoTypeInformation

Get-ADReplicationSiteLink -Filter * | Select-Object Name, Cost,
    ReplicationFrequencyInMinutes,
    @{N='SitesIncluded';E={$_.SitesIncluded -join '; '}} |
    Export-Csv -Path "$OutputRoot\AD_SiteLinks.csv" -NoTypeInformation

Write-Host "DC enumeration complete. Outputs:"
Get-ChildItem $OutputRoot -Filter "AD_DomainControllers*.csv","AD_FSMO_Roles.csv","AD_Sites*.csv","AD_SiteLinks.csv" | Select-Object Name, Length
