# AI Security KQL Queries

20 tested KQL queries for finding shadow AI and AI misuse with Microsoft Sentinel and Defender.

**File names:** `<table>_<what it does>_<version>.md`
**Inside each file:** one code block. Copy the whole block into the portal. The `//` comment lines don't run.
**Each header says:** what it does, the goal, where to run it, and tips.

## Two places to run queries
- **Defender advanced hunting:** anything on `AgentsInfo` (folders 02 and 03)
- **Sentinel workspace > Logs:** everything else (folders 01, 04, 05)

`AgentsInfo` and `CopilotActivity` may not be available in the same place, so joining them can fail.

---

## 01_workspace_checks: what data do we have?

| File | What it answers |
|---|---|
| `usage_ingestion_inventory_v1` | Which tables flow into the workspace, and are they fresh? |
| `usage_table_readability_check_v1` | Can I read this table at all? |
| `usage_time_range_check_v1` | What time range does the data cover? |
| `usage_zscaler_source_check_v1` | Are proxy logs (e.g. Zscaler) in the workspace? |
| `securityalert_house_pattern_v1` | How are existing alerts built, and does one already exist for my topic? |

## 02_agent_inventory: how many agents, and what kind?

| File | What it answers |
|---|---|
| `agents_schema_check_v1` | What are the real column names in my tenant? |
| `agents_total_count_v1` | How many agents in total? |
| `agents_count_by_platform_v1` | How many agents per platform? |
| `agents_with_entra_identity_count_v1` | How many agents have their own Entra identity? |
| `agents_find_sharing_columns_v1` | Which column shows who an agent is shared with? |

## 03_agent_sensitive_purpose_hunt: agents doing potentially sensitive work

| File | What it answers |
|---|---|
| `agents_sensitive_terms_count_by_term_v1` | Which words cause the most matches? |
| `agents_sensitive_purpose_hunt_v1_baseline` | Which agents potentially do sensitive work? (first version, noisy) |
| `agents_sensitive_purpose_hunt_v2_tuned` | Same, whole-word matching (current version) |
| `agents_sensitive_match_snippets_v1` | Where did the word match, with a snippet? |

## 04_copilot_activity: what's happening in Copilot?

| File | What it answers |
|---|---|
| `copilotactivity_jailbreak_hunt_v1` | Which messages were flagged as jailbreak attempts? |
| `copilot_and_foundry_agent_inventory_v1` | Which Copilot and Foundry agents were actually used? |

## 05_identity_and_azure: sign-ins, consents, Azure AI resources

| File | What it answers |
|---|---|
| `signinlogs_ai_apps_via_sso_v1` | Which AI apps do people log into with corporate SSO? |
| `auditlogs_ai_app_consent_grants_v1` | Which AI apps were given access to data? |
| `azureactivity_ai_resource_creation_v1` | Who created Azure AI resources? |
| `azureactivity_ai_control_plane_changes_v1` | Model deployments, key pulls, content filter changes |

---

## Rules for this folder
1. Add a query only after it has been tested.
2. Never put real names, results, prompts or company details in a file. Any `ActorName`, `UserPrincipalName`, `Caller`, `Actor` or `Owners` value is a real person.
3. A new version is a new file (`_v2`, `_v3`), not an overwrite.
4. `TimeGenerated` and `Timestamp` are in UTC.
