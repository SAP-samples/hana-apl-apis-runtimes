# How to check APL installation
## Purpose
This script validate APL is properly installed by:
1. checking basic prerequisites
    * APL plugin is actually installed (!)
    * Script Server is activated
2. checking installation of low level APL functions
3. checking installation of APL high level helpers (SQLScripts artefacts, APL role, APL Delivery Unit,...)
4. checking known deployment issues of APL
5. checking APL runtime
    * train using procedure mode
    * apply using procedure mode
    * ping

A report is done on each test and a global analysis is done.

## Audience
DBAs or DevOps can run this script each time an issue is reported with APL in order to quickly understand if issue is a bad installation or a functional issue. 

In case of a bad installation is detected, outputs can be provided to APL support for detailed analysis.

## Perimeter and dependencies
This script can be run on HANA 2.x and Hana Cloud. **HANA 1.2 is not supported**.
It analyzes APL artifacts delivered via a Delivery Unit as well as new Hana Cloud's SQL Auto Content.

This is a pure SQLScript, meaning it can be run on server side as well as client side (even Windows) as soon as the HANA client *hdbsql* is available

## Assumptions and prerequisites
* The password of HANA's SYSTEM User is known
* A temporary user CHECK_APL will be (re)-created and dropeed after execution. This user is reserved and must not be used to keep any important artefact.
* Concurrent executions of this script are not supported.

## Cleanup
This script is designed to always delete all objects (technical user, code, tables ) at end of execution. As a result, no artefact of any kind is kept after execution and there is no manual cleanup to do.

If for an unexpected reason, this cleanup step has not been done, manual cleanup can be done with (connected as SYSTEM or DBADMIN)
```SQL
DROP USER CHECK_APL CASCADE;
```

## Command line
```bash
 HANA_SYSTEM_PASSWORD=<HANA SYSTEM USER password>; CHECK_APL_PASSWORD=Password1 ;hdbsql -n HANA host name>:<port> -u SYSTEM -p $HANA_SYSTEM_PASSWORD -g "" -V SYSTEM_PASSWORD=$HANA_SYSTEM_PASSWORD,CHECK_APL_PASSWORD=$CHECK_APL_PASSWORD -j -A -I check_apl.sql
 ````
Example:
```bash
HANA_SYSTEM_PASSWORD=Manager1; CHECK_APL_PASSWORD=Password1 ;hdbsql -n hana:30015 -u SYSTEM -p $HANA_SYSTEM_PASSWORD -g "" -V SYSTEM_PASSWORD=$HANA_SYSTEM_PASSWORD,CHECK_APL_PASSWORD=$CHECK_APL_PASSWORD -j -A -I /SAPDevelop/apl/src/sql/check_apl/check_apl.sql
```
Output can be saved in a text file and then provided to APL support with:

```bash
HANA_SYSTEM_PASSWORD=Manager1; CHECK_APL_PASSWORD=Password1 ;hdbsql -n hana:30015 -u SYSTEM -p $HANA_SYSTEM_PASSWORD -g "" -V SYSTEM_PASSWORD=$HANA_SYSTEM_PASSWORD,CHECK_APL_PASSWORD=$CHECK_APL_PASSWORD -j -A -I /SAPDevelop/apl/src/sql/check_apl/check_apl.sql
 >/tmp/check_apl_results.txt 2>&1
 ```

## Results
The script outputs a resultset with 3 parts:
1. High level analysis of APL install and APL runtime. Global Status can be *OK* or *ERROR*
2. A detailed list of checks done. Status of each check can be *OK* or *ISSUE*
3. Full ping informations : version of HANA, APL,...

Example of results when APL is not installed (HANA On Premise)

>| KEY                                           | STATU | DETAILS                                  |
>| --------------------------------------------- | ----- | ---------------------------------------- |
>| ===== HANA On Premise !! =====                |       |                                          |
>| ===== APL is NOT installed !! =====           | ISSUE |                                          |
>| ===== Script Server is not activated !! ===== | ISSUE | APL even if installed, cannot be called! |
>| ===== APL is not installed at ALL =====       | ERROR |                                          |

Example of results on a valid APL installation (HANA Cloud)


>| KEY                                                                               | STAT | DETAILS                                         |
>| --------------------------------------------------------------------------------- | ---- | ----------------------------------------------- |
>| Analysis of install of APL plugin properly ended                                  | OK   |                                                 |
>| Analysis of APL basic runtime properly ended                                      | OK   |                                                 |
>| Analysis of APL deployment issue properly ended                                   | OK   |                                                 |
>| Analysis of APL train properly ended                                              | OK   |                                                 |
>| Analysis of APL apply properly ended                                              | OK   |                                                 |
>| All tests were done. List of detected issues is supposed to be complete           |      |                                                 |
>| No issue detected in APL install/runtime                                          | OK   
>| ============================                                                      |      |                                                 |
>| ===== APL informations =====                                                      |      |                                                 |
>| ============================                                                      |      |                                                 |
>| APL.Version.Major                                                                 |      | 4                                               |
>| APL.Version.Minor                                                                 |      | 400                                             |
>| APL.Version.ServicePack                                                           |      | 2209                                            |
>| APL.Version.Patch                                                                 |      | 1                                               |
>| APL.Info                                                                          |      | Automated Predictive Library                    |
>| AFLSDK.Version.Major                                                              |      | 2                                               |
>| AFLSDK.Version.Minor                                                              |      | 16                                              |
>| AFLSDK.Version.Patch                                                              |      | 0                                               |
>| AFLSDK.Info                                                                       |      | 2.16.0                                          |
>| AFLSDK.Build.Version.Major                                                        |      | 2                                               |
>| AFLSDK.Build.Version.Minor                                                        |      | 13                                              |
>| AFLSDK.Build.Version.Patch                                                        |      | 0                                               |
>| AutomatedAnalytics.Version.Major                                                  |      | 10                                              |
>| AutomatedAnalytics.Version.Minor                                                  |      | 2209                                            |
>| AutomatedAnalytics.Version.ServicePack                                            |      | 1                                               |
>| AutomatedAnalytics.Version.Patch                                                  |      | 0                                               |
>| AutomatedAnalytics.Info                                                           |      | Automated Analytics                             |
>| HDB.Version                                                                       |      | 4.00.000.00.1651574580                          |
>| SQLAutoContent.Date                                                               |      | 2022-04-19                                      |
>| SQLAutoContent.Version                                                            |      | 4.400.2209.1                                    |
>| SQLAutoContent.Caption                                                            |      | Automated Predictive SQL Library for Hana Cloud |
>| ============================                                                      |      |                                                 |
>| ===== APL informations =====                                                      |      |                                                 |
>| -------------------------------------------                                       |      |                                                 |
>|                                                                                   |      |                                                 |
>| Here are the full logs of analysis                                                |      |                                                 |
>| -------------------------------------------                                       |      |                                                 |
>| ===== HANA Cloud !! =====                                                         |      |                                                 |
>| ===== APL is installed !! =====                                                   | OK   |                                                 |
>| ===== Script Server is activated !! =====                                         | OK   |                                                 |
>| Checking installation of APL plugin                                               |      |                                                 |
>| -----------------------------------                                               |      |                                                 |
>| Good high level status of APL AFL install                                         | OK   | REGISTRATION SUCCESSFUL                         |
>| Checking registration of low level APL API                                        |      |                                                 |
>| ---------------------------------------                                           |      |                                                 |
>| Good # of APL AREA                                                                | OK   | 1                                               |
>| Good # of APL PACKAGES                                                            | OK   | 1                                               |
>| Good # of APL low level calls                                                     | OK   | 55                                              |
>| Good # of descriptions of APL low level calls                                     | OK   | 841                                             |
>| Checking registration of high level APL API (APL DU or Hana Cloud SQLAutoContent) |      |                                                 |
>| ---------------------------------------                                           |      |                                                 |
>| Good # of APL roles                                                               | OK   | 3                                               |
>| Main APL role sap.pa.apl.base.roles::APL_EXECUTE is declared                      | OK   | 1                                               |
>| Good # of APL artefacts                                                           | OK   | 114                                             |
>| Good # of high level APL APIs                                                     | OK   | 78                                              |
>| grant successful "sap.pa.apl.base.roles::APL_EXECUTE" to CHECK_APL                | OK   |                                                 |
>| Checking installation of APL plugin                                               | Done |                                                 |
>| -----------------------------------                                               |      |                                                 |
>| Checking deployment issues of APL plugin                                          |      |                                                 |
>| -----------------------------------------------                                   |      |                                                 |
>| Checking deployment issues of APL plugin                                          | Done |                                                 |
>| -----------------------------------------------                                   |      |                                                 |
>| Checking APL basic run time                                                       |      |                                                 |
>| ---------------------------                                                       |      |                                                 |
>| Checking PING (proc mode)                                                         |      |                                                 |
>| Calling proc PING successful                                                      | OK   |                                                 |
>| Analyzing results of PING                                                         |      |                                                 |
>| proc PING results looks like OK                                                   | OK   | 21                                              |
>| Found HCE tags in proc PING results                                               | OK   | 3                                               |
>| -----------------------------------                                               |      |                                                 |
>| Checking PING (direct mode)                                                       |      |                                                 |
>| Calling direct PING successful                                                    | OK   |                                                 |
>| Analyzing results of PING                                                         |      |                                                 |
>| direct PING results looks like OK                                                 | OK   | 17                                              |
>| Checking APL basic run time                                                       | Done |                                                 |
>| ---------------------------                                                       |      |                                                 |
>| Checking train in procedure mode                                                  |      |                                                 |
>| -----------------------------------------------                                   |      |                                                 |
>| # of test records                                                                 | OK   | 500                                             |
>| Train in procedure mode                                                           | OK   |                                                 |
>| Checking train in procedure mode                                                  | Done |                                                 |
>| -----------------------------------------------                                   |      |                                                 |
>| Checking apply in procedure mode                                                  |      |                                                 |
>| -----------------------------------------------                                   |      |                                                 |
>| # of output rows                                                                  | OK   | 500                                             |
>| Checking apply in procedure mode                                                  | Done |                                                 |
>| -----------------------------------------------                                   |      |                                                 |




