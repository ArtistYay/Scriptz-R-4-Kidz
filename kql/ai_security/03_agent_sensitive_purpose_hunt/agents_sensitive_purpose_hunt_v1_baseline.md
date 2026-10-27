# agents_sensitive_purpose_hunt_v1_baseline

Copy everything inside the code block into Defender advanced hunting.

```kql
// =====================================================================
// FILE:         agents_sensitive_purpose_hunt_v1_baseline
// WHAT IT DOES: Finds active, published agents whose Name, Description or Instructions
//                mention a sensitive business purpose (credit, payroll, legal, trading,
//                and so on). One row per agent, with the words it matched.
// GOAL:         First version of the sensitive-purpose hunt: which agents are
//                potentially doing sensitive work, so they can be reviewed.
// WHERE TO RUN: Defender portal > Hunting > Advanced hunting
// TABLE:        AgentsInfo
// STATUS:       Tested and working.
// NOTES:
//               - Uses `contains`, which also matches inside other words, so it's noisy.
//                  Use v2_tuned for real work.
//               - Findings are "potentially" sensitive until reviewed.
//               - The Owners column holds real people. Keep it out of demos.
// =====================================================================

// The sensitive words to look for
let SensitiveTerms = dynamic([
    "loan", "credit decision", "underwrit", "mortgage", "investment advice", "trading",
    "payroll", "salary", "compensation", "termination", "performance review", "disciplinary", "hiring decision",
    "legal advice", "litigation", "contract review",
    "money laundering", "insider trading"]);
AgentsInfo
// Latest row for each agent
| summarize arg_max(Timestamp, *) by AgentId
// Live agents only
| where PublishedStatus == "Published" and LifecycleStatus == "Active"
// One lowercase text to search per agent
| extend SearchText = tolower(strcat(coalesce(Name, ""), " ", coalesce(Description, ""), " ", coalesce(Instructions, "")))
// One row per (agent, word), keep matches only
| mv-expand Term = SensitiveTerms to typeof(string)
| where SearchText contains Term
// Back to one row per agent, listing every word that matched
| summarize MatchReason = make_set(Term),
            Owners = take_any(Owners),
            SharedWith = take_any(SharedWith),
            Platform = take_any(Platform),
            Availability = take_any(Availability),
            LastPublishedDateTime = take_any(LastPublishedDateTime)
    by AgentId, Name, PublishedStatus
// Pick and order the columns to show
| project AgentName = Name, Owners, Platform, MatchReason, PublishedStatus, Availability, SharedWith, LastPublishedDateTime, AgentId
| order by LastPublishedDateTime desc
```
