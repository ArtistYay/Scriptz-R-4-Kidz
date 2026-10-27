# Deploy-CISBaseline.ps1 - Quick Start Guide

## Overview

Automated deployment script for CIS 3.0 Accelerator benchmarks to Microsoft Intune. Deploys configuration policies and remediation scripts via Microsoft Graph API with idempotent behavior.

## Prerequisites

### PowerShell Modules
```powershell
Install-Module -Name Microsoft.Graph.Authentication -MinimumVersion 2.0.0 -Scope CurrentUser
Install-Module -Name Microsoft.Graph.DeviceManagement -MinimumVersion 2.0.0 -Scope CurrentUser
```

### Permissions
- **Microsoft Graph API Scope**: `DeviceManagementConfiguration.ReadWrite.All`
- User must be **Intune Administrator** or **Global Administrator**

## Usage

### Basic Execution
```powershell
cd "Office365/Intune"
.\Deploy-CISBaseline.ps1
```

### Interactive Menu
1. **Select Benchmark**:
   - `[1]` Windows 11 Intune v3.0.1 (38 policies)
   - `[2]` Edge Enterprise v2.0.0 (3 policies)
   - `[3]` Google Chrome Enterprise v3.0.0 (10 policies)
   - `[4]` Office Intune v1.0.0
   - `[5]` All Benchmarks

2. **Select Tier(s)**:
   - `[1]` L1 only (Level 1 - basic security)
   - `[2]` L2 only (Level 2 - high security)
   - `[3]` BL only (Baseline)
   - `[4]` NG only (Next Generation)
   - `[5]` All Tiers
   - `[6]` L1 + L2 (recommended)

3. **Confirm** deployment (Y/N)

### WhatIf Mode (Simulation)
```powershell
.\Deploy-CISBaseline.ps1 -WhatIf
```

## How It Works

### Idempotent Deployment
- **Create**: Policy doesn't exist → Create new policy
- **Update**: Policy exists but settings differ → Update settings
- **Skip**: Policy exists and settings identical → No changes

### Comparison Logic
Uses SHA256 hash comparison of policy settings arrays to detect changes.

### Remediation Scripts
- Deploys PowerShell scripts for settings not configurable via Intune policies
- Auto-generates detection script (always returns exit code 1 to force remediation)
- Uploads to `deviceHealthScripts` endpoint

### Error Handling
- **Retry logic**: 3 attempts with exponential backoff (2s, 4s, 8s) for HTTP 429/503
- **Continue on error**: Failed policies logged but deployment continues
- **CMTrace-compatible logging**: `Logs/Deploy-CISBaseline.log`

## Output

### Console Output
Real-time progress with color-coded severity:
- White = Info
- Yellow = Warning
- Red = Error

### Log Files
- **Location**: `Office365/Intune/Logs/`
- **Format**: CMTrace-compatible (viewable in CMTrace or text editor)
- **File**: `Deploy-CISBaseline.log`

### Summary Report
CSV export: `Logs/CIS-Deployment-Summary-{timestamp}.csv`

**Columns**:
| Column | Description |
|--------|-------------|
| PolicyName | CIS policy display name |
| Benchmark | Windows 11, Edge, Chrome, or Office |
| Tier | L1, L2, BL, or NG |
| Action | Create, Update, Skip |
| PolicyID | Intune policy GUID |
| Status | Success or error message |

## Example Workflow

### First-Time Deployment (New Tenant)
```powershell
.\Deploy-CISBaseline.ps1

# Select: [1] Windows 11 Intune v3.0.1
# Select: [6] L1 + L2
# Confirm: Y

# Result: ~38 policies created + remediation scripts deployed
```

### Update Existing Policies
```powershell
.\Deploy-CISBaseline.ps1

# Select same options as before
# Result: Only changed policies updated, rest skipped
```

### Deploy Additional Benchmarks
```powershell
.\Deploy-CISBaseline.ps1

# Select: [2] Edge Enterprise v2.0.0
# Select: [5] All Tiers
# Confirm: Y

# Result: Edge policies added to existing deployment
```

## Post-Deployment Steps

**CRITICAL**: Policies are created **unassigned** to prevent accidental mass deployment.

1. **Navigate to Intune Portal**:
   - `Devices` → `Configuration Policies`

2. **Filter by "CIS"** to find deployed policies

3. **Assign to Pilot Group**:
   - Select policy → `Assignments` → Add pilot device group
   - Monitor compliance for 24-48 hours

4. **Validate Compliance**:
   - `Devices` → `Monitor` → `Device compliance`
   - Check pilot devices show expected compliance status

5. **Expand to Production**:
   - Add production groups to assignments after successful pilot

## Troubleshooting

### "CIS 3.0 Accelerator directory not found"
**Cause**: Script can't find templates directory  
**Fix**: Ensure script is in `Office365/Intune/` and templates exist in `CIS 3.0 Accelerator/`

### "Missing required module"
**Cause**: Microsoft.Graph modules not installed  
**Fix**: Run prerequisites installation commands above

### "Authentication failed"
**Cause**: Missing permissions or user not authorized  
**Fix**: Ensure user has Intune Administrator role, consent to scopes when prompted

### HTTP 403 Forbidden
**Cause**: Insufficient Graph API permissions  
**Fix**: Admin consent required for `DeviceManagementConfiguration.ReadWrite.All`

### Policy already exists but not detected
**Cause**: Policy name changed in Intune after creation  
**Fix**: Delete renamed policy in portal, re-run script to create fresh

## Verification Commands

### Check Deployed Policies
```powershell
Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All"
Get-MgDeviceManagementConfigurationPolicy | Where-Object { $_.Name -like "CIS*" } | Select-Object Id, Name, CreatedDateTime
```

### Check Remediation Scripts
```powershell
Get-MgDeviceManagementDeviceHealthScript | Where-Object { $_.DisplayName -like "*CIS*" } | Select-Object Id, DisplayName
```

### View Logs
```powershell
# In CMTrace
CMTrace.exe "Logs/Deploy-CISBaseline.log"

# Or PowerShell
Get-Content "Logs/Deploy-CISBaseline.log" -Tail 50
```

## Rollback

**To remove deployed policies**:
1. Navigate to Intune Portal → `Devices` → `Configuration Policies`
2. Filter by "CIS"
3. Select all CIS policies
4. Click `Delete`

**Note**: Script does not include delete functionality to prevent accidental mass deletion.

## Architecture Notes

### Why UTF-16 LE Encoding?
CIS JSON templates use UTF-16 LE (not UTF-8). Script uses `Get-Content -Encoding Unicode` to read correctly.

### Why Minimal Detection Script?
CIS remediation scripts are standalone (no separate detection). Auto-generated detection script always returns exit code 1 to force remediation on every check.

### Why No Auto-Assignment?
Prevents accidental deployment to all devices. Manual assignment ensures controlled pilot/rollout.

## Support

**Issues**: Report in repository Issues tracker  
**Documentation**: See `CIS 3.0 Accelerator/README.md` for CIS benchmark details  
**Logs**: Always attach `Deploy-CISBaseline.log` and summary CSV when reporting issues
