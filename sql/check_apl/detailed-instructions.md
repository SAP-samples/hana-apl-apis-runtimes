# Running `check_apl` on a HANA instance — DevOps guide

Comprehensive step-by-step for running the APL installation check and returning its report to SAP support.

**Audience.** DBAs / DevOps engineers comfortable with Linux, HANA administration and the `hdbsql` command-line client.

---

## 1. Prerequisites

### 1.1. HANA instance and credentials

- The target instance is either HANA **2.x** (On-Premise) or **HANA Cloud**. HANA 1.2 is **not** supported.
- The user you connect with needs the `USER ADMIN` privilege (the launcher creates and drops a temporary `CHECK_APL` user). In practice:
  - **HANA On-Premise** → `SYSTEM` with its password.
  - **HANA Cloud** → `DBADMIN` with its password. `SYSTEM` is reserved on HANA Cloud and cannot be used.
- You need the **tenant** DB host and SQL port. On multi-tenant On-Premise instances make sure it's the tenant hosting APL, not the SYSTEMDB (typical ports: `303<instance>15` for tenant, `303<instance>13` for SYSTEMDB).
- Concurrent runs of `check_apl` against the same instance are **not** supported (they all try to (re)create the same `CHECK_APL` user).

### 1.2. `hdbsql` availability

The launcher shells out to `hdbsql` — no Java, no Python, no ODBC/JDBC. On a HANA host it is already installed under one of:

```
/hana/shared/<SID>/hdbclient/hdbsql
/usr/sap/hdbclient/hdbsql
```

On any other machine (laptop, jump host, CI worker) install the **SAP HANA Client** from launchpad.support.sap.com, or via `apt`/`rpm`, and make sure `hdbsql` is on `PATH`. The launcher probes the standard locations if it isn't.

### 1.3. Launcher script

Only **one** file needs to be transferred to the machine where you'll run the check — the SQL is embedded:

- Linux / macOS → `check_apl.sh`
- Windows → `check_apl.ps1` (PowerShell 5.1+)

---

## 2. Where to run it — pick one

### 2.1. Client-side (laptop, jump host, CI worker)

Anywhere `hdbsql` reaches the tenant's SQL port. Typical setup:

```sh
mkdir apl-check && cd apl-check
# copy check_apl.sh here (scp / curl / release archive)
chmod +x check_apl.sh
./check_apl.sh -h <hana-host>:<sql-port> -u SYSTEM -p '<password>' -o hana.md.txt
```

PowerShell equivalent:
```powershell
mkdir apl-check ; cd apl-check
# copy check_apl.ps1 here
.\check_apl.ps1 -HanaHost <hana-host>:<sql-port> -User SYSTEM -Password '<password>' -OutputFile hana.md.txt
```

If PowerShell's execution policy blocks it:
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\check_apl.ps1 `
    -HanaHost <hana-host>:<sql-port> -User SYSTEM -Password '<password>' -OutputFile hana.md.txt
```

### 2.2. Server-side (SSH'd onto the HANA host as `<sid>adm`)

Same command line, `<hana-host>` is typically `localhost`. Use the tenant DB port (e.g. `30041`), not the SYSTEMDB port.

```sh
./check_apl.sh -h localhost:30041 -u SYSTEM -p '<password>' -o hana.md.txt
```

### 2.3. HANA Cloud specifics

- Always use `DBADMIN`, never `SYSTEM`.
- Keep SSL **on** (the default). HANA Cloud rejects unencrypted connections.
- The host is your `<uuid>.hana.<region>.hanacloud.ondemand.com` name; port is typically `443`.

```sh
./check_apl.sh -h <uuid>.hana.<region>.hanacloud.ondemand.com:443 \
               -u DBADMIN -p '<password>' -o hana.md.txt
```

---

## 3. Parameters reference

> **You do not have to pass any parameter.** Every required value is prompted for interactively when it is missing from the command line, so simply running
> ```sh
> ./check_apl.sh
> ```
> (or `.\check_apl.ps1` on Windows) is a perfectly valid — and often preferred — way to invoke the launcher. It avoids leaking the HANA password in your shell history and in the process list, and it is the fastest path for a one-off run. Passing parameters explicitly is only needed for scripted / non-interactive use (CI, cron, ticket automation) or to override one of the optional defaults below, usually at the request of SAP support.

Both launchers accept the same set of options; only the flag spelling differs.

### 3.1. Required (or interactively prompted)

| Linux flag | PowerShell parameter | Meaning |
|---|---|---|
| `-h` / `--host` | `-HanaHost` | `host:port` of the tenant DB |
| `-u` / `--system_user` | `-User` | `SYSTEM` (On-Premise) or `DBADMIN` (HANA Cloud) |
| `-p` / `--system_password` | `-Password` | Password for that user |
| `-o` | `-OutputFile` | Output file (default `hana.md.txt`); use `stdout` to stream to console |

Any of these that you omit is prompted for interactively — the password prompt hides the input.

### 3.2. Optional

| Linux flag | PowerShell parameter | Description | Default |
|---|---|---|---|
| `-f` / `--format` | `-Format` | Output format: `md` (Markdown, table-based) or `raw` (line-per-row, easier to grep) | `md` |
| `-s` / `--signal-error` | `-SignalError` | Emit `SQL_ERROR_CODE 10001` and a non-zero exit when checks fail — turn `on` for CI use | `off` |
| `--use-ssl` | `-UseSsl` | Pass `-e -ssltrustcert` to `hdbsql`. Turn `off` only for a bare, non-TLS On-Premise instance | `on` |
| `--check_apl-password` | `-CheckAplPassword` | Password for the temporary `CHECK_APL` user | `Password01Password01` |
| `--show-cmd-only` | `-ShowCmdOnly` | Print the assembled `hdbsql` command (with the password masked) and exit — useful for reproducing the run manually | — |
| `--help` | `Get-Help .\check_apl.ps1` | Show help and exit | — |

---

## 4. Exit codes and pre-check errors

The launcher runs a small pre-check **before** the main script to fail fast on the two conditions that would otherwise waste a run. Both codes are matched textually by the wrapper:

| Code | Meaning | Fix |
|---|---|---|
| `10001` | The connecting user does **not** have `USER ADMIN`. | Reconnect as `SYSTEM` (On-Premise) or `DBADMIN` (HANA Cloud). |
| `10002` | The default `CHECK_APL` password (`Password01Password01`) does **not** satisfy the instance's password policy. | Re-run with `--check_apl-password '<policy-compliant-pwd>'` (Linux) or `-CheckAplPassword '<pwd>'` (PowerShell). |

Retry after fixing:

```sh
./check_apl.sh -h ... -u DBADMIN -p '...' \
               --check_apl-password '<policy-compliant-pwd>' -o hana.md.txt
```

```powershell
.\check_apl.ps1 -HanaHost ... -User DBADMIN -Password '...' `
                -CheckAplPassword '<policy-compliant-pwd>' -OutputFile hana.md.txt
```

Other errors you may run into:

- **`hdbsql exit code 3`** — bad host / port / user / password combination, or SSL required and disabled (or vice-versa).
- **`hdbsql: not found`** — HANA Client is not installed on the machine you're running from, and none of the standard `/hana/shared/*/hdbclient` / `/usr/sap/hdbclient` paths exist. Install it or run the script from a HANA host.
- **`Connection refused` / `Timeout`** — firewall or wrong port; try the tenant port explicitly.

---

## 5. Cleanup

Cleanup is automatic. The final phase of `check_apl.sql` runs `DROP USER CHECK_APL CASCADE` as the caller (`SYSTEM` / `DBADMIN`). Nothing is left behind: no schema objects, no roles, no data.

If a previous run crashed mid-execution and left `CHECK_APL` behind, the next run will re-create it cleanly. To clean up manually, connect as `SYSTEM` / `DBADMIN` and run:

```sql
DROP USER CHECK_APL CASCADE;
```

---

## 6. Collecting the result

The output file (default `hana.md.txt`) is a Markdown report. Sanity-check it before sending:

```sh
ls -l hana.md.txt        # confirm it's non-empty (>10 KB typically)
head -50 hana.md.txt     # eyeball the pre-analysis section
grep -c '^##' hana.md.txt  # rough section count
```

Attach `hana.md.txt` to your SAP support ticket **as-is**. Do **not** rename it to `.md`: some mail systems, ticket portals and SAP internal tools drop or rewrite `.md` attachments — the `.txt` suffix is intentional.

---

## 7. Troubleshooting the launcher itself

### 7.1. `./check_apl.sh: /bin/bash^M: bad interpreter: No such file or directory` (Linux only)

The file was corrupted with Windows CRLF line endings during transfer (browser download, WinSCP text mode, e-mail attachment, `unzip -a`, …). Repair in place:

```sh
sed -i 's/\r$//' check_apl.sh
chmod +x check_apl.sh
./check_apl.sh -h ... -u ... -p ... -o hana.md.txt
```

The launcher also **self-heals** when invoked as `bash check_apl.sh` — it detects `\r` in its own source, writes a scrubbed copy under `mktemp`, and `exec`s it. The direct-execution form (`./check_apl.sh`) can't self-heal because the kernel rejects the shebang first, so the `sed` step above is required in that case.

### 7.2. PowerShell reports "cannot be loaded because running scripts is disabled"

Either loosen the policy for the current process:
```powershell
Set-ExecutionPolicy -Scope Process Bypass
```
…or bypass just for this invocation:
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\check_apl.ps1 ...
```

### 7.3. `invalid user name`,`Not recommended feature` warnings

Harmless HANA warnings.

### 7.4. Reproducing the exact `hdbsql` invocation

Add `--show-cmd-only` (Linux) or `-ShowCmdOnly` (PowerShell) — the launcher prints the assembled command with the password masked and exits, so you can paste it, substitute the password back in and run it by hand.
