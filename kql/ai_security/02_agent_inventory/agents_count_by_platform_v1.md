# agents_count_by_platform_v1

Copy everything inside the code block into Defender advanced hunting.

```kql
// =====================================================================
// FILE:         agents_count_by_platform_v1
// WHAT IT DOES: Counts agents per platform (Agent Builder, Copilot Studio, Foundry,
//                and so on).
// GOAL:         Explain why different portals show different agent counts.
// WHERE TO RUN: Defender portal > Hunting > Advanced hunting
// TABLE:        AgentsInfo
// STATUS:       Tested and working.
// NOTES:
//               - Use dcount(AgentId), not count(). count() counts ROWS, and AgentsInfo
//                  has many rows per agent.
//               - Personal Agent Builder agents usually dominate the total. They run on
//                  the creator's own permissions with no identity of their own, so they
//                  are usually not the governance priority.
// =====================================================================

AgentsInfo
// dcount = count of DIFFERENT agents per platform
| summarize Agents = dcount(AgentId) by Platform
| order by Agents desc
```
