# agents_sensitive_terms_count_by_term_v1

Copy everything inside the code block into Defender advanced hunting.

```kql
// =====================================================================
// FILE:         agents_sensitive_terms_count_by_term_v1
// WHAT IT DOES: Counts how many active, published agents match each sensitive word
//                (loan, payroll, legal advice, and so on).
// GOAL:         Find which words cause the most matches, so you know what to tune in
//                the sensitive-purpose hunt.
// WHERE TO RUN: Defender portal > Hunting > Advanced hunting
// TABLE:        AgentsInfo
// STATUS:       Tested and working.
// NOTES:
//               - One agent can match several words, so counts add up to more than
//                  the number of agents.
//               - Uses `contains`, so it also matches inside other words
//                  ("determination" contains "termination").
//               - arg_max(Timestamp, *) by AgentId keeps one row per agent. Don't
//                  remove it.
// =====================================================================

// The sensitive words to look for. Edit this list in ONE place only.
let SensitiveTerms = dynamic([
    "loan", "credit decision", "underwrit", "mortgage", "investment advice", "trading",
    "payroll", "salary", "compensation", "termination", "performance review", "disciplinary", "hiring decision",
    "legal advice", "litigation", "contract review",
    "money laundering", "insider trading"]);
AgentsInfo
// Keep only the latest row for each agent
| summarize arg_max(Timestamp, *) by AgentId
// Keep only agents that are live
| where PublishedStatus == "Published" and LifecycleStatus == "Active"
// Join name + description + instructions into one lowercase text to search
| extend SearchText = tolower(strcat(coalesce(Name, ""), " ", coalesce(Description, ""), " ", coalesce(Instructions, "")))
// Make one row per (agent, word), then keep only real matches
| mv-expand Term = SensitiveTerms to typeof(string)
| where SearchText contains Term
// How many different agents does each word pull in?
| summarize Agents = dcount(AgentId) by Term
| order by Agents desc
```
