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
    * ping (direct mode as well as procedure mode)
    * train using procedure mode
    
A report is done on each test and a global analysis is done.

## Audience
DBAs or DevOps can run this script each time an issue is reported with APL in order to quickly understand if issue is a bad installation or a functional issue. 

In case of a bad installation is detected, outputs can be provided to APL support for detailed analysis.

## Perimeter and dependencies
This script can be run on HANA 2.x and Hana Cloud. **HANA 1.2 is not supported**.
It analyzes APL artifacts delivered via a Delivery Unit as well as new Hana Cloud's SQL Auto Content.

This is a pure SQLScript, meaning it can be run on server side as well as client side (even Windows) as soon as the HANA client *hdbsql* is available

## Assumptions and prerequisites
* **The command line tool _hdbsql_ can be used to connect to HANA**
* The password of HANA's SYSTEM User is known
* A temporary user CHECK_APL will be (re)-created and dropped after execution. This user is reserved and must not be used to keep any important artefact.
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

## if you cannot have access to SYSTEM user or hdbsql tool cannot be used
It means the user checking APL will be created by a dbadmin user. Dbadmin user will also be responsible of final cleanup.
In such a case, the process become:

* Ask dbadmin to create user CHECK_APL with this setup:

**HANA On Premise**
```SQL
CREATE USER CHECK_APL PASSWORD Password1;
ALTER USER CHECK_APL DISABLE PASSWORD lifetime;

-- needed to make a deep analysis of APL's DU state
GRANT SELECT ON "_SYS_REPO"."DELIVERY_UNITS" TO CHECK_APL;
GRANT SELECT ON "_SYS_REPO"."ACTIVE_OBJECT" TO CHECK_APL;

-- standard APL rights
GRANT AFL__SYS_AFL_APL_AREA_EXECUTE TO CHECK_APL;
GRANT AFLPM_CREATOR_ERASER_EXECUTE TO CHECK_APL;
CALL "_SYS_REPO"."GRANT_ACTIVATED_ROLE" ('sap.pa.apl.base.roles::APL_EXECUTE','CHECK_APL');
```

**HANA Cloud**
```SQL
CREATE USER CHECK_APL PASSWORD Password1;
ALTER USER CHECK_APL DISABLE PASSWORD lifetime;

-- standard APL rights
GRANT AFL__SYS_AFL_APL_AREA_EXECUTE TO CHECK_APL;
GRANT AFLPM_CREATOR_ERASER_EXECUTE TO CHECK_APL;
GRANT "sap.pa.apl.base.roles::APL_EXECUTE" TO CHECK_APL;
```

* Use your favorite SQL tool (HANA studio or HANA ide) to run the SQL script [check_apl_without_creating_check_apl_user.sql](./check_apl_without_creating_check_apl_user.sql)
* Ask dbadmin to cleanup the user CHECK_APL
```SQL
DROP USER CHECK_APL CASCADE;
```

## Results
A result set with 3 columns:
* Short description of the check
* High level status (OK,WARNING,ERROR) 
* Detailed infos on the result of the check

Example of results (APL fully OK on HANA On Premise)

| KEY                                                                                             | STATUS                                 | DETAILS                                                                                                                   |
| ----------------------------------------------------------------------------------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| ===== HANA On Premise !! =====                                                                  |                                        |                                                                                                                           |
| ===== APL is installed !! =====                                                                 | OK                                     |                                                                                                                           |
| ===== Script Server is activated !! =====                                                       | OK                                     |                                                                                                                           |
| Checking installation of APL plugin                                                             |                                        |                                                                                                                           |
| ____________________________                                                                    |                                        |                                                                                                                           |
| Good high level status of APL AFL install                                                       | OK                                     | REGISTRATION SUCCESSFUL                                                                                                   |
| Checking registration of low level APL API                                                      |                                        |                                                                                                                           |
|                                                                                                 |                                        |                                                                                                                           |
| Good # of APL AREA                                                                              | OK                                     | 1                                                                                                                         |
| Good # of APL PACKAGES                                                                          | OK                                     | 1                                                                                                                         |
| Good # of APL low level calls                                                                   | OK                                     | 55                                                                                                                        |
| Good # of descriptions of APL low level calls                                                   | OK                                     | 841                                                                                                                       |
| Checking registration of high level APL API (APL DU or Hana Cloud SQLAutoContent)               |                                        |                                                                                                                           |
|                                                                                                 |                                        |                                                                                                                           |
| APL DU Version                                                                                  |                                        | 2215                                                                                                                      |
| APL DU Update date                                                                              |                                        | 2022-06-14 10:06:50.0690000                                                                                               |
| Good # of APL roles                                                                             | OK                                     | Expected roles AFL__SYS_AFL_APL_AREA_EXECUTE,sap.pa.apl.base.roles::APL_EXECUTE,AFLPM_CREATOR_ERASER_EXECUTE are declared |
| Main APL role sap.pa.apl.base.roles::APL_EXECUTE is declared                                    | OK                                     | 1                                                                                                                         |
| Good # of APL types and tables                                                                  | OK                                     | 180                                                                                                                       |
| Good # of high level APL APIs                                                                   | OK                                     | 164                                                                                                                       |
| Expected debrief version in SQL code                                                            |                                        | 1.3.4.0                                                                                                                   |
| Checking installation of APL plugin                                                             | Done                                   |                                                                                                                           |
| Checking deployment issues of APL plugin                                                        |                                        |                                                                                                                           |
| ____________________________                                                                    |                                        |                                                                                                                           |
| Effective deployment of APL for user CHECK_APL                                                  | OK                                     | 164 effective APL APIS                                                                                                    |
| Checking deployment issues of APL plugin                                                        | Done                                   |                                                                                                                           |
| ____________________________                                                                    |                                        |                                                                                                                           |
| Checking APL basic run time                                                                     |                                        |                                                                                                                           |
| Checking PING (direct mode)                                                                     |                                        |                                                                                                                           |
| ping direct                                                                                     | APL.Version.Major                      | 4                                                                                                                         |
| ping direct                                                                                     | APL.Version.Minor                      | 203                                                                                                                       |
| ping direct                                                                                     | APL.Version.ServicePack                | 2215                                                                                                                      |
| ping direct                                                                                     | APL.Version.Patch                      | 0                                                                                                                         |
| ping direct                                                                                     | APL.Info                               | Automated Predictive Library                                                                                              |
| ping direct                                                                                     | AFLSDK.Version.Major                   | 2                                                                                                                         |
| ping direct                                                                                     | AFLSDK.Version.Minor                   | 16                                                                                                                        |
| ping direct                                                                                     | AFLSDK.Version.Patch                   | 0                                                                                                                         |
| ping direct                                                                                     | AFLSDK.Info                            | 2.16.0                                                                                                                    |
| ping direct                                                                                     | AFLSDK.Build.Version.Major             | 2                                                                                                                         |
| ping direct                                                                                     | AFLSDK.Build.Version.Minor             | 13                                                                                                                        |
| ping direct                                                                                     | AFLSDK.Build.Version.Patch             | 0                                                                                                                         |
| ping direct                                                                                     | AutomatedAnalytics.Version.Major       | 10                                                                                                                        |
| ping direct                                                                                     | AutomatedAnalytics.Version.Minor       | 2215                                                                                                                      |
| ping direct                                                                                     | AutomatedAnalytics.Version.ServicePack | 0                                                                                                                         |
| ping direct                                                                                     | AutomatedAnalytics.Version.Patch       | 0                                                                                                                         |
| ping direct                                                                                     | AutomatedAnalytics.Info                | Automated Analytics                                                                                                       |
| Calling direct PING successful                                                                  | OK                                     |                                                                                                                           |
| Checking PING (proc mode)                                                                       |                                        |                                                                                                                           |
| Looks like CHECK_APL has everything to call APL DU proc sap.pa.apl.base::PING                   | OK                                     |                                                                                                                           |
| Try to really call sap.pa.apl.base::PING)                                                       |                                        |                                                                                                                           |
| ping proc                                                                                       | HDB.Version                            | 2.00.059.00.1636704142                                                                                                    |
| ping proc                                                                                       | APL.Version.Major                      | 4                                                                                                                         |
| ping proc                                                                                       | APL.Version.Minor                      | 203                                                                                                                       |
| ping proc                                                                                       | APL.Version.ServicePack                | 2215                                                                                                                      |
| ping proc                                                                                       | APL.Version.Patch                      | 0                                                                                                                         |
| ping proc                                                                                       | APL.Info                               | Automated Predictive Library                                                                                              |
| ping proc                                                                                       | AFLSDK.Version.Major                   | 2                                                                                                                         |
| ping proc                                                                                       | AFLSDK.Version.Minor                   | 16                                                                                                                        |
| ping proc                                                                                       | AFLSDK.Version.Patch                   | 0                                                                                                                         |
| ping proc                                                                                       | AFLSDK.Info                            | 2.16.0                                                                                                                    |
| ping proc                                                                                       | AFLSDK.Build.Version.Major             | 2                                                                                                                         |
| ping proc                                                                                       | AFLSDK.Build.Version.Minor             | 13                                                                                                                        |
| ping proc                                                                                       | AFLSDK.Build.Version.Patch             | 0                                                                                                                         |
| ping proc                                                                                       | AutomatedAnalytics.Version.Major       | 10                                                                                                                        |
| ping proc                                                                                       | AutomatedAnalytics.Version.Minor       | 2215                                                                                                                      |
| ping proc                                                                                       | AutomatedAnalytics.Version.ServicePack | 0                                                                                                                         |
| ping proc                                                                                       | AutomatedAnalytics.Version.Patch       | 0                                                                                                                         |
| ping proc                                                                                       | AutomatedAnalytics.Info                | Automated Analytics                                                                                                       |
| Calling proc PING successful                                                                    | OK                                     |                                                                                                                           |
| Checking APL basic run time                                                                     | Done                                   |                                                                                                                           |
| Checking runtime train in procedure mode                                                        |                                        |                                                                                                                           |
| ____________________________                                                                    |                                        |                                                                                                                           |
| Looks like CHECK_APL has everything to call APL DU proc sap.pa.apl.base::CREATE_MODEL_AND_TRAIN | OK                                     |                                                                                                                           |
| Try to really call sap.pa.apl.base::CREATE_MODEL_AND_TRAIN                                      |                                        |                                                                                                                           |
| Call APL DU proc sap.pa.apl.base::CREATE_MODEL_AND_TRAIN has been successful                    | OK                                     |                                                                                                                           |
| Checking runtime train in procedure mode                                                        | Done                                   |                                                                                                                           |
| ==============================                                                                  |                                        |                                                                                                                           |
| ==============================                                                                  |                                        |                                                                                                                           |
| Analysis of results                                                                             |                                        |                                                                                                                           |
| Analysis of install of APL plugin properly ended                                                | OK                                     |                                                                                                                           |
| Analysis of APL deployment issue properly ended                                                 | OK                                     |                                                                                                                           |
| Analysis of APL basic runtime properly ended                                                    | OK                                     |                                                                                                                           |
| Analysis of runtime train proc properly ended                                                   | OK                                     |                                                                                                                           |
| No issue detected in APL install/runtime                                                        | OK                                     |                                                                                                                           |
| All tests were done. List of detected issues is supposed to be complete                         |                                        |                                                                                                                           |
| ==============================                                                                  |                                        |                                                                                                                           |
| ==============================                                                                  |                                        |                                                                                                                           |
```



