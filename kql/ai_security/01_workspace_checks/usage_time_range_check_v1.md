# usage_time_range_check_v1

Copy everything inside the code block into the Sentinel workspace (Logs).

```kql
// =====================================================================
// FILE:         usage_time_range_check_v1
// WHAT IT DOES: Counts rows and shows the oldest and newest record in the Usage table,
//                split by billable vs. free.
// GOAL:         Troubleshooting. Shows what time range the data really covers, so you
//                can tell if a time filter or the IsBillable filter is hiding results.
// WHERE TO RUN: Sentinel workspace > Logs
// TABLE:        Usage
// STATUS:       Tested and working.
// NOTES:
//               - Useful when the portal time picker and an in-query time filter
//                  cancel each other out.
// =====================================================================

Usage
// No time filter on purpose: we want to see the full range
| summarize
    Rows   = count(),
    Oldest = min(TimeGenerated),
    Newest = max(TimeGenerated)
  by IsBillable
```
