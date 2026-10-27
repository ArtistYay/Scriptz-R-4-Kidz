# agents_with_entra_identity_count_v1

Copy everything inside the code block into Defender advanced hunting.

```kql
// =====================================================================
// FILE:         agents_with_entra_identity_count_v1
// WHAT IT DOES: Counts agents that have their OWN Entra identity (EntraAgentId is
//                filled in).
// GOAL:         Find the agents that matter most for governance. An agent with its own
//                identity has its own permissions and can act beyond one user's access.
// WHERE TO RUN: Defender portal > Hunting > Advanced hunting
// TABLE:        AgentsInfo
// STATUS:       Tested and working.
// NOTES:
//               - Compare to the Entra admin center's agent count. Expect a gap; check
//                  dedup, lifecycle status, ingestion lag, and identities vs. blueprints.
//               - Column names are case-sensitive. If EntraAgentId fails, check the
//                  spelling with agents_schema_check_v1.
// =====================================================================

AgentsInfo
// Keep only agents that were given their own Entra identity
| where isnotempty(EntraAgentId)
// One row per agent, then count them
| distinct AgentId
| count
```
