# copilot_and_foundry_agent_inventory_v1

Copy everything inside the code block into the Sentinel workspace (Logs).

```kql
// =====================================================================
// FILE:         copilot_and_foundry_agent_inventory_v1
// WHAT IT DOES: Builds one list of agents that were ACTIVE, from two sources that don't
//                overlap:
//                  1. CopilotActivity: M365 Copilot and Copilot Studio agents (last 1 day)
//                  2. CloudAppEvents: agents built in Azure AI Foundry
// GOAL:         See which agents are actually being USED (not just exist), across both
//                Copilot and Foundry.
// WHERE TO RUN: Sentinel workspace > Logs
// TABLE:        CopilotActivity, CloudAppEvents
// STATUS:       Tested and working.
// NOTES:
//               - The Copilot side looks at 1 day. The Foundry side has NO time filter,
//                  so it scans all retention (slower).
//               - Agent name lives in different fields per product, so coalesce()
//                  tries each one in order.
// =====================================================================

// ---------- Part 1: M365 / Copilot Studio agents ----------
let CopilotAgents = CopilotActivity
    | where TimeGenerated > ago(1d)
    // LLMEventData is JSON text; turn it into an object
    | extend Parsed = todynamic(LLMEventData)
    // Security Copilot keeps the agent name inside a nested array
    | extend SecurityCopilotAgentName = trim(@" \t\r\n", tostring(Parsed.Resource[0].Property))
    // Take the first non-empty agent name from all the possible fields
    | extend NormalizedAgentName = coalesce(
        tostring(AgentName),
        SecurityCopilotAgentName,
        tostring(Parsed.AgentDisplayName),
        tostring(Parsed.agentName),
        tostring(Parsed.Agent.Name),
        tostring(Parsed.Title),
        tostring(Parsed.agent.displayName),
        tostring(Parsed.BotName),
        tostring(Parsed.bot.name),
        tostring(Parsed.AgentName),
        tostring(Parsed.Name)
    )
    // Label the agent type from the app identity
    | extend AgentType = case(
        AppIdentity startswith "Copilot.Studio.Declarative.", "Declarative Agent",
        AppIdentity startswith "Copilot.Studio.",             "Copilot Studio",
        isnotempty(Workload),                                 Workload,
        "Other"
    )
    // Some events have no AgentId. Use a cleaned-up name instead so the
    // agent isn't dropped from the list.
    | extend InventoryKey = case(
        isnotempty(AgentId), tostring(AgentId),
        AgentType == "Security Copilot" and isnotempty(SecurityCopilotAgentName), SecurityCopilotAgentName,
        isnotempty(NormalizedAgentName), tolower(replace_regex(NormalizedAgentName, @"[^a-zA-Z0-9]", "")),
        ""
    )
    | where isnotempty(InventoryKey)
    // Remove Microsoft's own built-in agents (noise)
    | where not(AppIdentity startswith "MicrosoftAgent.")
    // Remove admin actions that aren't agent use
    | where not(RecordType in ("CreateCopilotPromptBook", "EnableCopilotPlugin", "DisableCopilotPlugin"))
    | extend DisplayAgentName = replace_regex(NormalizedAgentName, @"^Skillsets\.", "")
    | summarize
        EventCount = count(),
        FirstSeen  = min(TimeGenerated),
        LastSeen   = max(TimeGenerated)
      by AgentName = DisplayAgentName, AgentId = InventoryKey
    | extend Source = "M365/Copilot Studio";
// ---------- Part 2: Azure AI Foundry agents ----------
let FoundryAgents = CloudAppEvents
    | where RawEventData has "AzureAIFoundry"
    | extend Event = parse_json(RawEventData)
    // "Target" fields = the agent being acted on; plain fields = the agent acting
    | extend AgentName = coalesce(tostring(Event.TargetAgentName), tostring(Event.AgentName))
    | extend AgentId   = coalesce(tostring(Event.TargetAgentId),   tostring(Event.AgentId))
    | where isnotempty(AgentName)
    | summarize
        EventCount = count(),
        FirstSeen  = min(TimeGenerated),
        LastSeen   = max(TimeGenerated)
      by AgentName, AgentId
    | extend Source = "Azure AI Foundry";
// ---------- Combine both lists ----------
CopilotAgents
| union FoundryAgents
| extend DaysSinceLastSeen = datetime_diff('day', LastSeen, now())
| project Source, AgentName, AgentId, FirstSeen, LastSeen, DaysSinceLastSeen, EventCount
| order by LastSeen desc
```
