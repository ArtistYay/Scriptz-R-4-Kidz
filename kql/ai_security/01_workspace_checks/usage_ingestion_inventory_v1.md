# usage_ingestion_inventory_v1

Copy everything inside the code block into the Sentinel workspace (Logs).

```kql
// =====================================================================
// FILE:         usage_ingestion_inventory_v1
// WHAT IT DOES: Lists every billable table flowing into the workspace, with its size (GB)
//                and hours since it last received data.
// GOAL:         Know what data the workspace actually collects before building any
//                detection. You can't alert on data that isn't there.
// WHERE TO RUN: Sentinel workspace > Logs
// TABLE:        Usage
// STATUS:       Tested and working.
// NOTES:
//               - Quantity is in MEGABYTES. Divide by 1024 for GB.
//               - IsBillable == true hides free tables. If a table you expect is
//                  missing, run again without that line.
//               - Set the time range in the portal picker OR in the query, never both.
//                  Mixing them can return 'no results' with no error.
//               - A table with real volume but an old LastSeen = a broken connector.
// =====================================================================

Usage
// Only tables that cost money to ingest (hides free-tier tables)
| where IsBillable == true
// Total size and last time data arrived, per table
| summarize
    TotalGB  = round(sum(Quantity) / 1024, 3),
    LastSeen = max(EndTime)
  by DataType
// Hours, not days: a feed that died 20 hours ago would round to "0 days"
| extend HoursSinceLastSeen = datetime_diff('hour', now(), LastSeen)
| order by TotalGB desc
```
