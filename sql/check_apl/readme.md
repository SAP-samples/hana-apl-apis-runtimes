# How to check APL installation
## Purpose
The script [check_apl.sql](./check_apl.sql) validate APL is properly installed by:
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
* The command line tool **_hdbsql_** **MUST** be used to connect to HANA
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
It means the user checking APL must be created, as a first step, by a dbadmin user. Dbadmin user will also be responsible of final cleanup.
In such a case, the process become:

* Ask dbadmin to create user CHECK_APL with this setup:

**HANA On Premise**
```SQL
CREATE USER CHECK_APL PASSWORD Password1;
ALTER USER CHECK_APL DISABLE PASSWORD lifetime;

-- needed to make a deep analysis of APL's DU state
GRANT SELECT ON "_SYS_REPO"."DELIVERY_UNITS" TO CHECK_APL;
GRANT SELECT ON "_SYS_REPO"."ACTIVE_OBJECT" TO CHECK_APL;

-- needed to see if a script server is activated
GRANT SERVICE ADMIN TO CHECK_APL;

-- standard APL rights
GRANT AFL__SYS_AFL_APL_AREA_EXECUTE TO CHECK_APL;
GRANT AFLPM_CREATOR_ERASER_EXECUTE TO CHECK_APL;
CALL "_SYS_REPO"."GRANT_ACTIVATED_ROLE" ('sap.pa.apl.base.roles::APL_EXECUTE','CHECK_APL');
```

**HANA Cloud**
```SQL
CREATE USER CHECK_APL PASSWORD Password1;
ALTER USER CHECK_APL DISABLE PASSWORD lifetime;

-- needed to see if a script server is activated
GRANT SERVICE ADMIN TO CHECK_APL;

-- standard APL rights
GRANT AFL__SYS_AFL_APL_AREA_EXECUTE TO CHECK_APL;
GRANT AFLPM_CREATOR_ERASER_EXECUTE TO CHECK_APL;
GRANT "sap.pa.apl.base.roles::APL_EXECUTE" TO CHECK_APL;
```

* Use your favorite SQL tool (HANA studio or HANA web ide) to run the SQL script [check_apl_without_creating_check_apl_user.sql](./check_apl_without_creating_check_apl_user.sql)
* Ask dbadmin to cleanup the user CHECK_APL
```SQL
DROP USER CHECK_APL CASCADE;
```

## Results
A result set with 3 columns:
* Short description of the check
* High level status (OK,WARNING,ISSUE) 
* Detailed infos on the result of the check

Example of results: [APL fully OK on HANA On Premise](./check_on_premise_ok.txt)
