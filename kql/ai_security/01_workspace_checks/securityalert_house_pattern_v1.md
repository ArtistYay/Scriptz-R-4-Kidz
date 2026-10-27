# securityalert_house_pattern_v1

Copy everything inside the code block into the Sentinel workspace (Logs).

```kql
// =====================================================================
// FILE:         securityalert_house_pattern_v1
// WHAT IT DOES: Lists the analytics alerts that fired in the last 30 days: name, count,
//                severity, MITRE tactics, entity types, and when it last fired.
// GOAL:         Learn how existing alerts are built (naming, severity, entity mapping)
//                so new detections match the house style. Works even when you can't open
//                the rule details. Also shows if a detection for your topic already exists
//                before you build a duplicate.
// WHERE TO RUN: Sentinel workspace > Logs
// TABLE:        SecurityAlert
// STATUS:       Tested and working.
// NOTES:
//               - TimeGenerated is UTC.
//               - If EntityTypes is empty everywhere, check the regex against a real
//                  Entities value before calling it a mapping gap.
// =====================================================================

SecurityAlert
| where TimeGenerated > ago(30d)
// Only alerts made by Sentinel analytics rules
| where ProductName == "Azure Sentinel" or ProviderName == "ASI Scheduled Alerts"
// Pull the entity types (Account, IP, Host...) out of the Entities JSON text
| extend EntityTypes = extract_all(@'"Type":"([^"]+)"', Entities)
// One row per alert name
| summarize
    Alerts      = count(),
    Severities  = make_set(AlertSeverity),
    Tactics     = make_set(Tactics),
    EntityTypes = make_set(EntityTypes),
    LastFired   = max(TimeGenerated)
  by AlertName
| order by LastFired desc
| take 25
```
