# How to check APL installation
## Purpose
The script [check_apl.sql](./check_apl.sql) does a full check of the APL (Automated Predictive Library) installation on a HANA server. It is designed to be run by DBAs or DevOps to quickly identify issues with APL installations, whether they are related to the installation itself or functional issues.

## Audience
DBAs or DevOps can run this script when asked by SAP support.

## Perimeter and dependencies
This script can be run on HANA 2.x and Hana Cloud. **HANA 1.2 is not supported**.

This is a pure SQLScript, meaning it can be run on server side as well as client side (even Windows) as soon as the HANA client *hdbsql* is available

## Assumptions and prerequisites
* The command line tool **_hdbsql_** **MUST** be used to connect to HANA
* The password of HANA's SYSTEM or DBADMIN User is known. On HANA Cloud, the user DBADMIN is recommended.
* A temporary user CHECK_APL will be (re)-created and dropped after execution. This user is reserved and must not be used to keep any important artefact.
* Concurrent executions of this script are not supported.

## Cleanup
This script is designed to always delete all objects (technical user, code, tables,types ) at end of execution. As a result, no artefact of any kind is kept after execution and there is no manual cleanup to do.

If for an unexpected reason, this cleanup step has not been done, manual cleanup can be done with (connected as SYSTEM or DBADMIN)
```SQL
DROP USER CHECK_APL CASCADE;
```

## Command line

To run the APL check script, use the provided `check_apl` shell script. This script will connect to your SAP HANA instance and execute the SQL checks automatically.

### Basic usage

```sh
check_apl -h <host:port> -u <user> -p <password> -o output_file
```

- `-h` or `--host` : HANA DB host and port (e.g., hana:30015)
- `-u` or `--system_user` : HANA DB user (e.g., SYSTEM)
- `-p` or `--system_password` : HANA DB user password
- `-o` : Output file to save the results (e.g., hana.md). Use stdout to see results in console
If any required parameter is missing, the script will prompt you interactively.

### Optional parameters

- `-f` or `--format <format>` : Output format (`md` for Markdown, `raw`, etc. Default: `md`)
- `-s` or `--signal-error <on|off>` : Signal error in output (Default: `off`)
- `--check_apl-password <password>` : Password for the temporary CHECK_APL user (Default: 
`Password1`)
- `--show-cmd-only` : Show only the final command line used to run the script and exit
- `--help` : Show help message and exit

### Output format and results.
Default for the script is to use Markdown format and redirect the output to a file named hana.md that can be communicated to SAP support.

```sh
./check_apl -h hana:30015 -u SYSTEM -p MyPassword -o hana.md
```

## Examples of results: 

* [APL fully OK on HANA On Premise](./check_on_premise_ok.txt)

* [APL fully OK on HANA Cloud](./check_hce_ok.txt)
