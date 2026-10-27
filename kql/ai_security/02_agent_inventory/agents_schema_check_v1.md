# agents_schema_check_v1

Copy everything inside the code block into Defender advanced hunting.

```kql
// =====================================================================
// FILE:         agents_schema_check_v1
// WHAT IT DOES: Lists every column in the AgentsInfo table, with its data type, as it
//                exists in YOUR tenant.
// GOAL:         Know the real column names before writing a query. Run it any time a
//                query fails with "column not found".
// WHERE TO RUN: Defender portal > Hunting > Advanced hunting
// TABLE:        AgentsInfo
// STATUS:       Tested and working.
// NOTES:
//               - Column names in a tenant can differ from Microsoft Learn (e.g. Name
//                  and Description instead of AgentName and AgentDescription). If they
//                  disagree, the tenant wins.
//               - Columns seen: Timestamp, AgentId, Name, Platform, Description,
//                  Version, PublishedStatus, LifecycleStatus, Availability,
//                  CreatedDateTime, LastPublishedDateTime, LastUpdatedDateTime, Owners,
//                  SharedWith, InstanceCount, Instructions, Model, Channels, Capabilities,
//                  DeclaredDataSources, DeclaredTools, McpServers, Skills,
//                  ConnectedAgents, Memory, Triggers, Guardrails, Endpoints,
//                  ObservabilityId.
// =====================================================================

AgentsInfo
| getschema   // returns one row per column: name, type
```
