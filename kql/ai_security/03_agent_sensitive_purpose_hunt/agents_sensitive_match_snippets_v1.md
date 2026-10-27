# agents_sensitive_match_snippets_v1

Copy everything inside the code block into Defender advanced hunting.

```kql
// =====================================================================
// FILE:         agents_sensitive_match_snippets_v1
// WHAT IT DOES: For each matching agent, shows WHERE the word was found (Name,
//                Description or Instructions) and a short snippet of the Instructions
//                around the match.
// GOAL:         Label an agent (benign / needs review / potentially risky) without
//                opening it or chatting with it.
// WHERE TO RUN: Defender portal > Hunting > Advanced hunting
// TABLE:        AgentsInfo
// STATUS:       Tested and working.
// NOTES:
//               - Reads the agent's own setup text, not user prompts.
//               - A match can be a rule telling the agent NOT to do something
//                  ("do not provide investment advice"). Read the snippet first.
//               - Remove `take 25` for the full list.
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
// Lowercase each field separately, so we can tell where the match was
| extend NameL = tolower(coalesce(Name, "")), DescL = tolower(coalesce(Description, "")), InstrL = tolower(coalesce(Instructions, ""))
// One row per (agent, word)
| mv-expand Term = SensitiveTerms to typeof(string)
// True/false flag for each field
| extend InName = NameL contains Term, InDescription = DescL contains Term, InInstructions = InstrL contains Term
| where InName or InDescription or InInstructions
// FoundIn = which fields matched.
// Snippet = 100 characters of Instructions, starting 40 characters before the match
| extend FoundIn = strcat(iff(InName, "Name ", ""), iff(InDescription, "Description ", ""), iff(InInstructions, "Instructions", "")),
         Snippet = iff(InInstructions, substring(InstrL, max_of(indexof(InstrL, Term) - 40, 0), 100), "")
// Back to one row per agent, with up to 3 snippets
| summarize Terms = make_set(Term), FoundIn = make_set(FoundIn), Snippets = make_set_if(Snippet, isnotempty(Snippet), 3),
            Platform = take_any(Platform), Availability = take_any(Availability)
    by AgentId, Name
| take 25
```
