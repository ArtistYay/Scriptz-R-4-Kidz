# auditlogs_ai_app_consent_grants_v1

Copy everything inside the code block into the Sentinel workspace (Logs).

```kql
// =====================================================================
// FILE:         auditlogs_ai_app_consent_grants_v1
// WHAT IT DOES: Finds times someone gave an AI app access to their Microsoft data
//                (OAuth consent), and which permissions it got.
// GOAL:         Catch third-party AI tools getting standing access to mail, files or
//                Graph. More serious than a sign-in.
// WHERE TO RUN: Sentinel workspace > Logs
// TABLE:        AuditLogs
// STATUS:       Tested and working.
// NOTES:
//               - Pattern from Microsoft's Entra security operations guide.
//               - No results can mean user consent is disabled tenant-wide.
//               - The [0] and [4] positions in modifiedProperties aren't guaranteed.
//                  Check against a real row.
//               - Note-taker apps often don't have "AI" in the name. Try once without
//                  the AppName filter.
//               - Actor is a REAL person.
// =====================================================================

AuditLogs
// Look-back window. Change as needed.
| where TimeGenerated > ago(90d)
| where OperationName == "Consent to application"
| where Result == "success"
// Pull app name, app ID and who consented out of the nested fields
| extend AppName = tostring(TargetResources[0].displayName),
         AppId   = tostring(TargetResources[0].id),
         Actor   = tostring(InitiatedBy.user.userPrincipalName)
// Was it admin consent, and what permissions were granted?
| extend IsAdminConsent = tostring(parse_json(tostring(TargetResources[0].modifiedProperties))[0].newValue)
| extend Permissions    = tostring(parse_json(tostring(TargetResources[0].modifiedProperties))[4].newValue)
// Keep only AI-looking apps
| where AppName has_any ("openai","chatgpt","claude","anthropic","gemini","perplexity","deepseek","cursor","otter","fireflies","copilot")
| project TimeGenerated, Actor, AppName, AppId, IsAdminConsent, Permissions
| order by TimeGenerated desc
```
