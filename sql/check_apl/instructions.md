# APL installation check — please run and return the report

To help us diagnose your APL (Automated Predictive Library) issue, please run the attached check script on your HANA instance and return the resulting report on this ticket.

## Attached to this ticket

- **`check_apl.sh`** — Linux / macOS launcher.
- **`check_apl.ps1`** — Windows / PowerShell launcher.
- **`detailed-instructions.md`** — full step-by-step for your DevOps / DBA team.

Both launchers are **self-contained**: no other file is needed, nothing is installed on your HANA instance.

## What your DevOps / DBA team needs to know

- **Prerequisites**: the standard HANA client tool `hdbsql` (shipped with any HANA Client install) and the connection details of the **TENANT DB, not the SYSTEM DB** where APL is (or should be) installed — host, SQL port, and the credentials of a HANA administrator on that tenant: `SYSTEM` on HANA On-Premise, `DBADMIN` on HANA Cloud.
- **Impact on your instance**: the script only reads state. It temporarily creates a dedicated `CHECK_APL` user, runs its checks under that user, and drops it at the end. Nothing is left behind.
- **How to run it (Linux / macOS)** — from a HANA host, or from any machine with the HANA Client installed:
  ```sh
  ./check_apl.sh
  ```
  The script will prompt all needed parameters. See `detailed-instructions.md` for details and command-line options. On Windows, use `check_apl.ps1` instead.
  On HANA Cloud, replace `SYSTEM` with `DBADMIN`. On Windows, use `check_apl.ps1` instead — see `detailed-instructions.md`.
- **Output**: a Markdown report, by default named `hana.md.txt`.

## What to send back

Attach the generated **`hana.md.txt`** to this ticket, unchanged. Please **do not rename the `.txt` extension** — some mail gateways and ticket systems drop `.md` attachments.

If the script fails to run or exits with an error code (`10001`, `10002`, `hdbsql exit code 3`, …), see the *Exit codes and pre-check errors* and *Troubleshooting* sections of `detailed-instructions.md`.
