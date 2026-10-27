# agents_find_sharing_columns_v1

Copy everything inside the code block into Defender advanced hunting.

```kql
// =====================================================================
// FILE:         agents_find_sharing_columns_v1
// WHAT IT DOES: Searches the AgentsInfo column list for any column whose name sounds
//                like sharing (share, avail, scope, audience, access).
// GOAL:         Find the column that says who an agent is shared with.
// WHERE TO RUN: Defender portal > Hunting > Advanced hunting
// TABLE:        AgentsInfo
// STATUS:       Tested and working.
// NOTES:
//               - If nothing comes back, run agents_schema_check_v1 instead. The
//                  documented columns are Availability and SharedWith.
// =====================================================================

AgentsInfo
| getschema   // list of columns
// keep columns whose name contains any of these words
| where ColumnName has_any ("share", "avail", "scope", "audience", "access")
| project ColumnName, ColumnType
```
