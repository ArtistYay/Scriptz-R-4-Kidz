# agents_total_count_v1

Copy everything inside the code block into Defender advanced hunting.

```kql
// =====================================================================
// FILE:         agents_total_count_v1
// WHAT IT DOES: Counts how many different AI agents exist in the tenant.
// GOAL:         Baseline number: "how many agents do we have?"
// WHERE TO RUN: Defender portal > Hunting > Advanced hunting
// TABLE:        AgentsInfo
// STATUS:       Tested and working.
// NOTES:
//               - Counts distinct AgentId, so repeated rows per agent aren't
//                  double-counted. Row count is NOT agent count.
//               - Not the same as the Entra agent identity count
//                  (see agents_with_entra_identity_count_v1).
// =====================================================================

AgentsInfo
| distinct AgentId   // one row per agent
| count              // how many rows = how many agents
```
