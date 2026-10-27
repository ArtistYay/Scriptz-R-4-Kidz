# copilotactivity_jailbreak_hunt_v1

Copy everything inside the code block into the Sentinel workspace (Logs).

```kql
// =====================================================================
// FILE:         copilotactivity_jailbreak_hunt_v1
// WHAT IT DOES: Finds Copilot messages that Microsoft flagged as a jailbreak attempt
//                (JailbreakDetected = true) in the last 7 days. One row per message.
// GOAL:         See how often jailbreak attempts happen and from where, so each hit
//                can be reviewed and labeled before anything goes to the SOC.
// WHERE TO RUN: Sentinel workspace > Logs (wherever CopilotActivity works)
// TABLE:        CopilotActivity
// STATUS:       Tested and working.
// NOTES:
//               - CopilotActivity holds metadata only. Prompt text lives in Purview
//                  (DSPM for AI > Activity explorer).
//               - To review a hit: take the user and date, find the prompt in Purview,
//                  label it potential attempt / likely false positive / unclear.
//               - Check SecurityAlert first: a built-in jailbreak rule may already exist.
//               - ActorName and ActorUserId are REAL people. Record labels only.
// =====================================================================

CopilotActivity
// Last 7 days (change to 1d or 30d as needed)
| where TimeGenerated > ago(7d)
// Only Copilot chat interactions
| where RecordType == "CopilotInteraction"
// LLMEventData is JSON text. Turn it into an object we can read.
| extend Parsed = todynamic(LLMEventData)
// One row per message inside the interaction
| mv-expand Msg = Parsed.Messages
// Keep only messages Microsoft flagged as a jailbreak attempt
| where tobool(Msg.JailbreakDetected) == true
// Columns to show: when, who, which agent, from where, which message
| project TimeGenerated, ActorName, ActorUserId, AgentName, SrcIpAddr,
          MessageId = tostring(Msg.Id), IsPrompt = tobool(Msg.isPrompt)
| order by TimeGenerated desc
```
