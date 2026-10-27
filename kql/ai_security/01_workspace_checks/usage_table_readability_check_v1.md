# usage_table_readability_check_v1

Copy everything inside the code block into the Sentinel workspace (Logs).

```kql
// =====================================================================
// FILE:         usage_table_readability_check_v1
// WHAT IT DOES: Returns 10 raw rows from a table. No filters.
// GOAL:         Troubleshooting. When a filtered query returns nothing, this tells you
//                which problem you have:
//                  - rows come back -> the table works; your filter is wrong
//                  - empty          -> the table has no data
//                  - error          -> you can't see this table (permissions)
// WHERE TO RUN: Sentinel workspace > Logs
// TABLE:        Usage (swap in any table name)
// STATUS:       Tested and working.
// =====================================================================

Usage
| take 10   // any 10 rows, no filtering
```
