# agents_sensitive_purpose_hunt_v2_tuned

Copy everything inside the code block into Defender advanced hunting.

```kql
// =====================================================================
// FILE:         agents_sensitive_purpose_hunt_v2_tuned
// WHAT IT DOES: Same hunt as v1, but matches whole words only, so "termination" no
//                longer matches inside "determination". One row per agent.
// GOAL:         Current version of the sensitive-purpose hunt. A smaller, more accurate
//                list of agents that potentially do sensitive work, for labeling and
//                routing.
// WHERE TO RUN: Defender portal > Hunting > Advanced hunting
// TABLE:        AgentsInfo
// STATUS:       Tested and working.
// NOTES:
//               - `has` = whole word. `contains` is used only for the stem "underwrit"
//                  (catches underwrite, underwriting, underwriter).
//               - Plurals are listed because `has` won't match "loans" from "loan".
//               - Lesson: whole-word matching cut only a little. Most volume came from
//                  common banking words, not words hidden inside other words.
//               - Tuning idea: only count loan/mortgage when the agent also mentions
//                  approving, denying or deciding.
//               - To label a sample, add  | sample 30  as the last line.
//               - Don't open or chat with an agent to test it.
//               - The Owners column holds real people. Keep it out of demos.
// =====================================================================

// Whole-word terms (matched with `has`)
let WordTerms = dynamic([
    "loan", "loans", "credit decision", "mortgage", "mortgages", "investment advice", "trading",
    "payroll", "salary", "compensation", "termination", "performance review", "disciplinary", "hiring decision",
    "legal advice", "litigation", "contract review",
    "money laundering", "insider trading"]);
// Word stems on purpose (matched with `contains`)
let StemTerms = dynamic(["underwrit"]);
AgentsInfo
// Latest row for each agent
| summarize arg_max(Timestamp, *) by AgentId
// Live agents only
| where PublishedStatus == "Published" and LifecycleStatus == "Active"
// One lowercase text to search per agent
| extend SearchText = tolower(strcat(coalesce(Name, ""), " ", coalesce(Description, ""), " ", coalesce(Instructions, "")))
// One row per (agent, term) across both lists
| mv-expand Term = array_concat(WordTerms, StemTerms) to typeof(string)
// Mark which terms are stems
| extend IsStem = Term in (StemTerms)
// Stems use contains; everything else needs a whole-word match
| where (IsStem and SearchText contains Term) or (not(IsStem) and SearchText has Term)
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
