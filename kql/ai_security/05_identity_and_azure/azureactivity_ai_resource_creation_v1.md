# azureactivity_ai_resource_creation_v1

Copy everything inside the code block into the Sentinel workspace (Logs).

```kql
// =====================================================================
// FILE:         azureactivity_ai_resource_creation_v1
// WHAT IT DOES: Finds who created Azure AI resources in the last 30 days: Cognitive
//                Services / Azure OpenAI accounts, Machine Learning workspaces, and AI
//                Search services.
// GOAL:         Catch unapproved models or AI services being stood up in Azure.
//                Control-plane data, so no endpoint agent is needed.
// WHERE TO RUN: Sentinel workspace > Logs
// TABLE:        AzureActivity
// STATUS:       Tested and working.
// NOTES:
//               - Caller often comes back as a GUID. Look it up in
//                  AADServicePrincipalSignInLogs or AADManagedIdentitySignInLogs.
//               - Managed identities log to a different table than app service
//                  principals.
//               - Expect most hits to be automation (service principals). The human
//                  callers are the ones to look at.
//               - Caller can be a REAL person.
// =====================================================================

AzureActivity
| where TimeGenerated > ago(30d)
// The three "create an AI resource" operations
| where OperationNameValue has_any (
    "MICROSOFT.COGNITIVESERVICES/ACCOUNTS/WRITE",          // Azure OpenAI / Cognitive Services
    "MICROSOFT.MACHINELEARNINGSERVICES/WORKSPACES/WRITE",  // ML / Foundry workspace
    "MICROSOFT.SEARCH/SEARCHSERVICES/WRITE"                // AI Search
  )
// Only ones that worked
| where ActivityStatusValue in ("Success", "Succeeded", "Accepted")
// Last part of the resource ID = the resource name
| extend ResourceName = tostring(split(_ResourceId, "/")[-1])
| project TimeGenerated, Caller, CallerIpAddress, OperationNameValue,
          ResourceGroup, ResourceName, SubscriptionId, _ResourceId
| sort by TimeGenerated desc
```
