# Scriptz-R-4-Kidz

One place for the scripts and queries I've written across my IT career, from my homelab and from professional work. It covers security automation, Active Directory assessments, Intune hardening, and threat hunting in Microsoft Sentinel and Defender.

Everything is sorted by language. Anything under [`script_kiddie/`](script_kiddie/) is me learning and practicing a language. Those files are exercises, not production tools.

> Everything here is shared as-is. Read a script before you run it, and test in a lab before you point it at production.

---

## Python

| Script | What it does |
|---|---|
| [combine_csv_files_to_excel.py](python/combine_csv_files_to_excel.py) | Merges every CSV in a folder into one Excel workbook, one sheet per CSV. Bolds and freezes the header row, adds filters, and sizes the columns. Needs `openpyxl`. |

**Usage:** `python combine_csv_files_to_excel.py <csv_directory> <output_xlsx_path>`

## PowerShell

### Active Directory

| Script | What it does |
|---|---|
| [Invoke-ADGroupPermissionAssessment.ps1](powershell/active_directory/Invoke-ADGroupPermissionAssessment.ps1) | Finds stale accounts, members of privileged groups (Domain Admins, Enterprise Admins, and so on), disabled accounts still in groups, and empty groups. Gives each a risk level and exports everything to CSV. |
| [Get-ADDomainControllerInventory.ps1](powershell/active_directory/Get-ADDomainControllerInventory.ps1) | Exports every domain controller, the FSMO role holders, functional levels, sites, subnets, and site links to CSV. |
| [Invoke-DCRetirementAssessment.ps1](powershell/active_directory/Invoke-DCRetirementAssessment.ps1) | Works offline from exported event logs (4768, 4769, 4770, 4771, 5156, 8004) and an AD computer export. Shows which clients still depend on a domain controller, so you know whether it's safe to retire. Supports a known-good suppression list with expiry dates. |

These need the `ActiveDirectory` module (RSAT) and read access to the domain.

### Intune

| Script | What it does |
|---|---|
| [Deploy-CISBaseline.ps1](powershell/intune/cis_baseline/Deploy-CISBaseline.ps1) | Deploys CIS benchmark policies and remediation scripts to Intune through Microsoft Graph. Creates new policies, updates changed ones, and skips identical ones, so it's safe to re-run. Supports `-WhatIf`. Policies are created unassigned on purpose. See the [guide](powershell/intune/cis_baseline/README.md). |

The CIS benchmark templates are not in this repo. They come from CIS under their own license.

### Windows

| Script | What it does |
|---|---|
| [Update-WingetPackages.ps1](powershell/windows/Update-WingetPackages.ps1) | Keeps installed software up to date. A scheduled task runs `winget source update` and `winget upgrade --all` at your first sign-in each month: on the 1st if the computer is on, or at the next sign-in after that if it isn't. Logs go to `%LOCALAPPDATA%\WingetMonthlyUpdate`. |

**Setup** (run once, from an Administrator PowerShell):

```powershell
.\Update-WingetPackages.ps1 -Register     # install the monthly task
.\Update-WingetPackages.ps1 -Force -WhatIf # dry run: show what would happen
.\Update-WingetPackages.ps1 -Unregister   # remove the task
```

To keep an app from being upgraded: `winget pin add --id <PackageId>`

## KQL

| Folder | What it does |
|---|---|
| [ai_security/](kql/ai_security/) | 20 tested hunting queries for finding shadow AI and AI misuse with Microsoft Sentinel and Defender advanced hunting: agent inventory, sensitive-purpose agents, Copilot jailbreak attempts, AI app consent grants, and Azure AI resource changes. The [query index](kql/ai_security/README.md) says what each one answers and where to run it. |

**Reference material (not my work):** [top_300_sentinel_kql_use_cases.pdf](kql/reference/top_300_sentinel_kql_use_cases.pdf), a community compilation of Sentinel KQL use cases that I learn from.

---

## Learning: `script_kiddie/`

This is where I practice. Some files are unfinished on purpose and say so at the top.

| Folder | Source |
|---|---|
| [claude_practice_questions/](script_kiddie/python/claude_practice_questions/) | CSV, date, and validation labs |
| [exercism_challenges/](script_kiddie/python/exercism_challenges/) | [Exercism](https://exercism.org/tracks/python) Python track |
| [one_week_of_python/](script_kiddie/python/one_week_of_python/) | Beginner basics: strings, input, math |
| [pynative/](script_kiddie/python/pynative/) | [PYnative](https://pynative.com/) beginner and file-handling exercises |
| [python_crash_course/](script_kiddie/python/python_crash_course/) | Exercises from *Python Crash Course* |
| [python_with_delvin/](script_kiddie/python/python_with_delvin/) | Classes, validation, and file practice sessions |

---

## Other projects

| Project | What it is |
|---|---|
| [azure-appsec-pipeline](https://github.com/ArtistYay/azure-appsec-pipeline) | Connects CI/CD and the SIEM, so the pipeline's deploy and scan context reaches the same place as runtime detections. |
| [codecrafters-git-python](https://github.com/ArtistYay/codecrafters-git-python) | A Git CLI built from scratch in Python. |

## Naming conventions

- **Python:** `snake_case.py` ([PEP 8](https://peps.python.org/pep-0008/)), formatted with [ruff](https://docs.astral.sh/ruff/)
- **PowerShell:** `Verb-Noun.ps1` using [approved verbs](https://learn.microsoft.com/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
- **KQL:** `<table>_<what_it_does>_v<version>.md`
- **Folders:** `snake_case`

## License

[MIT](LICENSE)
