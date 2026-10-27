# usage_zscaler_source_check_v1

Copy everything inside the code block into the Sentinel workspace (Logs).

```kql
// =====================================================================
// FILE:         usage_zscaler_source_check_v1
// WHAT IT DOES: Checks if a proxy/firewall source (e.g. Zscaler) sends logs into the
//                workspace, by looking for CommonSecurityLog, Syslog, or a table named
//                like "zscaler".
// GOAL:         Find out if browser use of consumer AI (ChatGPT, Claude, etc.) can be
//                seen through proxy logs, which matters when there's no endpoint agent.
// WHERE TO RUN: Sentinel workspace > Logs
// TABLE:        Usage, then CommonSecurityLog
// STATUS:       Tested and working.
// NOTES:
//               - Run Part 1 first. Only run Part 2 if CommonSecurityLog shows up.
// =====================================================================

// Part 1: does any proxy-type table exist?
Usage
| where TimeGenerated > ago(30d)
| where DataType in ("CommonSecurityLog","Syslog") or DataType has "zscaler"
| summarize TotalMB = sum(Quantity), LastSeen = max(TimeGenerated) by DataType

// Part 2 (only if CommonSecurityLog appeared): which vendors send to it?
// CommonSecurityLog
// | where TimeGenerated > ago(1d)
// | summarize count() by DeviceVendor, DeviceProduct
```
