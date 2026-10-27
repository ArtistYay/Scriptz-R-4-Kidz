# azureactivity_ai_control_plane_changes_v1

Copy everything inside the code block into the Sentinel workspace (Logs).

```kql
// =====================================================================
// FILE:         azureactivity_ai_control_plane_changes_v1
// WHAT IT DOES: Finds AI-related changes in Azure in the last 30 days and labels each:
//                Model deployment, Content filter change, Key retrieval, Resource creation.
// GOAL:         Wider than azureactivity_ai_resource_creation_v1. Also covers model
//                deployments and content (safety) filter changes.
// WHERE TO RUN: Sentinel workspace > Logs
// TABLE:        AzureActivity
// STATUS:       Tested and working.
// NOTES:
//               - Key retrieval = someone uses API keys instead of Entra ID. That's a
//                  posture observation, not an abuse finding.
//               - Check whether the model name appears in Properties_d in your tenant.
//               - Caller can be a REAL person.
// =====================================================================

AzureActivity
| where TimeGenerated > ago(30d)
| where ActivityStatusValue in ("Success","Succeeded","Accepted")
| where OperationNameValue has_any (
    "MICROSOFT.COGNITIVESERVICES/ACCOUNTS/DEPLOYMENTS/WRITE",    // model deployed
    "MICROSOFT.COGNITIVESERVICES/ACCOUNTS/RAIPOLICIES/WRITE",    // content filter created/changed
    "MICROSOFT.COGNITIVESERVICES/ACCOUNTS/LISTKEYS/ACTION",      // API keys retrieved
    "MICROSOFT.COGNITIVESERVICES/ACCOUNTS/WRITE",                // AI account created/changed
    "MICROSOFT.MACHINELEARNINGSERVICES/WORKSPACES/WRITE")        // ML workspace created/changed
| extend ResourceName = tostring(split(_ResourceId, "/")[-1])
// Plain-English label for each operation
| extend Category = case(
    OperationNameValue has "DEPLOYMENTS", "Model deployment",
    OperationNameValue has "RAIPOLICIES", "Content filter change",
    OperationNameValue has "LISTKEYS",    "Key retrieval",
    "Resource creation")
| project TimeGenerated, Category, Caller, ResourceName, OperationNameValue, _ResourceId, Properties_d
| order by TimeGenerated desc
```
