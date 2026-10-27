# signinlogs_ai_apps_via_sso_v1

Copy everything inside the code block into the Sentinel workspace (Logs).

```kql
// =====================================================================
// FILE:         signinlogs_ai_apps_via_sso_v1
// WHAT IT DOES: Finds successful sign-ins to AI apps (OpenAI, Claude, Gemini,
//                Perplexity, etc.) that used a corporate Entra account, last 30 days.
// GOAL:         Spot third-party AI SaaS that people log into with their work identity.
// WHERE TO RUN: Sentinel workspace > Logs
// TABLE:        SigninLogs
// STATUS:       Tested and working.
// NOTES:
//               - "copilot" also matches Microsoft's own apps. Build an allowlist of
//                  sanctioned AppIds, then treat any new AI AppId as a finding.
//               - Empty is NOT proof of no use: personal-account browser use never
//                  touches Entra.
//               - SampleUsers holds REAL people. Don't share results.
// =====================================================================

// Words that appear in AI app names. "copilot" will also match Microsoft's
// sanctioned apps, so expect those in the results.
let AIAppPatterns = dynamic(["openai","chatgpt","anthropic","claude","gemini","perplexity","deepseek","cursor","mistral","huggingface","copilot"]);
SigninLogs
| where TimeGenerated > ago(30d)
// "0" = successful sign-in
| where ResultType == "0"
| where AppDisplayName has_any (AIAppPatterns)
// One row per app: how many sign-ins and how many different people
| summarize
    SignIns     = count(),
    Users       = dcount(UserPrincipalName),
    SampleUsers = make_set(UserPrincipalName, 10),
    FirstSeen   = min(TimeGenerated),
    LastSeen    = max(TimeGenerated)
  by AppDisplayName, AppId
| order by Users desc
```
