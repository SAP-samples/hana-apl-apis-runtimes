-- ================================================================
-- @required(hanaMinimumVersion,2.0.30)
-- This script is compatible with HANA 2 and Hana Cloud
-- The purpose of this script is to validate the APL installation by:
--	check APL is actually installed
--		APL plugin is installed
--		Script server is actovate 
-- check APL is properly installed:
--      APL low level functions are installed
--      APL high level functions are installed
--      APL rights are available and can be granted
--		check some weel known issue in APL installation
--  check APL run time is OK:
--      check APL ping can be called
--      check results of APL ping
--		create from scratch a minimal input dataset
--		check a train can be done using procedure mode
-- 		check an apply can be done using procedure mode
-- 
-- Assumption: The scripserver is already enabled 
--
-- Output: a result set with 3 parts
--  High level status (OK,ERROR) for install checks as well as run time checks 
--  Detailed infos on each check. Status can be OK or ISSUE
--  A copy of the APL ping results which provide detailed version informations

-- Command line to run this script is:
-- hdbsql -n <HostName>:<port> -u SYSTEM -p <System password> -I .check_apl.sql -g '' -V SYSTEM_PASSWORD=<System password> -j -A 
-- Ex: hdbsql -n localhost:30041 -u SYSTEM -p Password1 -I ./check_apl.sql -g '' -V SYSTEM_PASSWORD=Password1 -j -A 

-- A more convenient way to run this script may be:
-- HANA_SYSTEM_PASSWORD=<HANA SYSTEM USER's password>; CHECK_APL_PASSWORD=Password1 ;hdbsql -n HANA host name>:<port> -u SYSTEM -p $HANA_SYSTEM_PASSWORD -g "" -V SYSTEM_PASSWORD=$HANA_SYSTEM_PASSWORD,CHECK_APL_PASSWORD=$CHECK_APL_PASSWORD -j -A -I check_apl.sql

-- Add >check_apl_results.tx 2>&1  at end of statement to save all out^put in a file and communicate it to support
-- Ex of a full actual call
-- HANA_SYSTEM_PASSWORD=Manager1; CHECK_APL_PASSWORD=Password1 ;/usr/sap/hdbclient_2_9_28/hdbsql -n hana:30015 -u SYSTEM -p $HANA_SYSTEM_PASSWORD -g "" -V SYSTEM_PASSWORD=$HANA_SYSTEM_PASSWORD,CHECK_APL_PASSWORD=$CHECK_APL_PASSWORD -j -A -I /SAPDevelop/apl/src/sql/check_apl/check_apl.sql >/tmp/b 2>&1

-- More details are available in readme.md

connect SYSTEM PASSWORD &SYSTEM_PASSWORD;


-- Prepare USER CHECK_APL
DO BEGIN
	DECLARE has_check_apl INTEGER;
	SELECT COUNT(*) into has_check_apl FROM "USERS" WHERE USER_NAME='CHECK_APL';
	IF :has_check_apl = 1
	THEN
		EXECUTE IMMEDIATE 'DROP USER CHECK_APL CASCADE';
	END IF;
END;


CREATE USER CHECK_APL PASSWORD &CHECK_APL_PASSWORD;
ALTER USER CHECK_APL DISABLE PASSWORD lifetime;

connect CHECK_APL PASSWORD &CHECK_APL_PASSWORD;
GRANT ALL PRIVILEGES ON SCHEMA "CHECK_APL" TO SYSTEM;



connect SYSTEM PASSWORD &SYSTEM_PASSWORD;
CREATE TYPE "CHECK_APL"."CHECK_RESULTS_T" AS TABLE ("KEY" NVARCHAR(255),"STATUS" NVARCHAR(256),"DETAILS" NVARCHAR(4098));

-- check basic prequisites:
--  APL is installed (!!)
-- Scriptserver is activated

CREATE FUNCTION "CHECK_APL"."HAS_APL"()
RETURNS has_apl BOOLEAN
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
DETERMINISTIC 
AS BEGIN
	DECLARE nb INT;
	SELECT COUNT(*) into nb FROM "M_PLUGIN_STATUS" WHERE "PLUGIN_NAME"='sap_afl_sdk_apl';
	IF :nb > 0 THEN
		has_apl := TRUE;
	ELSE
		has_apl := FALSE;
	END IF;
END;

CREATE FUNCTION "CHECK_APL"."HAS_SCRIPTSERVER"()
RETURNS has_scriptserver BOOLEAN
LANGUAGE SQLSCRIPT
-- Be careful : Use DEFINER otherwise a standard user cannot check if the script server is activated!
SQL SECURITY DEFINER
AS BEGIN
	DECLARE nb INT;
	SELECT COUNT(*) INTO nb FROM "M_SERVICES" WHERE "SERVICE_NAME" = 'scriptserver';
	IF :nb > 0 THEN
		has_scriptserver := TRUE;
	ELSE
		has_scriptserver := FALSE;
	END IF;
END;


-- recreate these types so we don't depend on a successfull deployment of APL types
CREATE TYPE "CHECK_APL"."PING_OUTPUT_T" AS TABLE (
	"name" VARCHAR(128),
	"value" VARCHAR(1024));

CREATE TYPE "CHECK_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID" AS TABLE (
    "OID" VARCHAR(50),
    "FORMAT" VARCHAR(50),
    "LOB" CLOB
);

CREATE TYPE "CHECK_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED" AS TABLE(
	"KEY" VARCHAR(1000),
    "VALUE" VARCHAR(5000),
    "CONTEXT" VARCHAR(100)

);

CREATE TYPE "CHECK_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER" AS TABLE(
	"KEY" VARCHAR(50),
    "VALUE" VARCHAR(255)
);

CREATE TYPE "CHECK_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID" AS TABLE(
	"NAME" VARCHAR(255),
    "ROLE" VARCHAR(10),
    "COMPOSITION_TYPE" VARCHAR(10),
    "COMPONENT_NAME" VARCHAR(255),
    "OID" VARCHAR(50)
);

CREATE TYPE "CHECK_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID" AS TABLE(
	"RANK" INTEGER,
    "NAME" VARCHAR(255),
    "STORAGE" VARCHAR(10),
    "VALUETYPE" VARCHAR(10),
    "KEYLEVEL" INTEGER,
    "ORDERLEVEL" INTEGER,
    "MISSINGSTRING" VARCHAR(255),
    "GROUPNAME" VARCHAR(255),
    "DESCRIPTION" VARCHAR(255),
    "OID" VARCHAR(50)
);

CREATE TYPE "CHECK_APL"."sap.pa.apl.base::BASE.T.TABLE_TYPE" as table (
    "OID" VARCHAR(50),
    "POSITION" INTEGER, 
    "NAME" VARCHAR(255), 
    "KIND" VARCHAR(50), 
    "PRECISION" INTEGER, 
    "SCALE" INTEGER, 
    "MAXIMUM_LENGTH" INTEGER
);

CREATE TYPE "CHECK_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG" AS TABLE (
    "OID" VARCHAR(50),
    "TIMESTAMP" TIMESTAMP,
    "LEVEL" INTEGER,
    "ORIGIN" VARCHAR(50),
    "MESSAGE" NCLOB
);


CREATE TYPE "CHECK_APL"."sap.pa.apl.base::BASE.T.SUMMARY" AS TABLE (
    "OID" VARCHAR(50),
    "KEY" VARCHAR(100),
    "VALUE" VARCHAR(100)
);

CREATE TYPE "CHECK_APL"."sap.pa.apl.base::BASE.T.INDICATORS" AS TABLE (
    "OID" VARCHAR(50),
    "VARIABLE" VARCHAR(255),
    "TARGET" VARCHAR(255),
    "KEY" VARCHAR(100),
    "VALUE" NCLOB,
    "DETAIL" NCLOB
);


-- this table is used only for regular On old (1.2) Premise HANA
CREATE TABLE "CHECK_APL"."COUNT_ACTIVE_OBJECTS" (NB_ACTIVE_OBJECTS INTEGER);

-- all results will be stored in this table
CREATE TABLE "CHECK_APL"."APL_CHECK_RESULTS" LIKE "CHECK_APL"."CHECK_RESULTS_T";




CREATE FUNCTION "CHECK_APL"."IS_HCE"()
RETURNS is_hce BOOLEAN
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
DETERMINISTIC 
AS BEGIN
	DECLARE major INT;
	SELECT CAST(SUBSTR_BEFORE ("VERSION", '.') AS INT) into major FROM "M_DATABASE";
	 IF :major >=4
	 THEN
	 	is_hce = true;
	 ELSE
	 	is_hce = false;
	 END IF;
END;


CREATE PROCEDURE "CHECK_APL"."SHAKE_APL_INSTALL"(OUT results "CHECK_APL"."CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE status_1 NVARCHAR(1000);
	DECLARE status_2 NVARCHAR(1000);
	DECLARE text_1 NVARCHAR(1000);
	DECLARE nb INTEGER;
	DECLARE du_version integer;
	DECLARE du_date DATETIME = NULL;
	DECLARE is_hce BOOLEAN = "CHECK_APL"."IS_HCE"();
	DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:results.insert(('SHAKE_APL_INSTALL SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
	END;
	IF "CHECK_APL"."HAS_APL"() = FALSE
	THEN
		RETURN;
	END IF;
	:results.insert(('Checking installation of APL plugin',NULL,NULL));
	:results.insert(('____________________________',NULL,NULL));

	SELECT "ERROR_TEXT" into text_1 FROM "M_PLUGIN_STATUS" WHERE "PLUGIN_NAME"='sap_afl_sdk_apl';

	SELECT "AREA_STATUS" into status_1 FROM "M_PLUGIN_STATUS" WHERE "PLUGIN_NAME"='sap_afl_sdk_apl';
	SELECT "PACKAGE_STATUS" into status_2 FROM "M_PLUGIN_STATUS" WHERE "PLUGIN_NAME"='sap_afl_sdk_apl';
	IF :status_1<>'REGISTRATION SUCCESSFUL' OR :status_2<>'REGISTRATION SUCCESSFUL'
	THEN
		:results.insert(('Bad high level status of APL AFL plugin','ISSUE',:status_1 || '/' || :status_2));
		:results.insert(('AFL diagnostic','ISSUE',:text_1));
	ELSE
		:results.insert(('Good high level status of APL AFL install','OK',:status_1));	
	END IF;
	:results.insert(('Checking registration of low level APL API',NULL,NULL));
	:results.insert(('____________________________',NULL,NULL));
	SELECT COUNT(*) into nb FROM "SYS"."AFL_AREAS" WHERE "AREA_NAME"='APL_AREA';
	IF :nb <> 1 
	THEN
		:results.insert(('Bad # of APL AREA','ISSUE',:nb));
	ELSE
		:results.insert(('Good # of APL AREA','OK',:nb));
	END IF;
	SELECT COUNT(*) into nb FROM "SYS"."AFL_PACKAGES" WHERE "AREA_NAME"='APL_AREA';
	IF :nb <> 1 
	THEN
		:results.insert(('Bad # of APL PACKAGES','ISSUE',:nb));
	ELSE
		:results.insert(('Good # of APL PACKAGES','OK',:nb));
	END IF;
	SELECT COUNT(*) into nb FROM "SYS"."AFL_FUNCTIONS_" F,
	    "SYS"."AFL_AREAS" A
	WHERE "A"."AREA_NAME"='APL_AREA'
	AND "A"."AREA_OID" = "F"."AREA_OID";
	-- 54 for master
	-- 52 for cor/pa 3.3
	IF :nb <52 
	THEN
		:results.insert(('Bad # of APL low level calls','ISSUE',:nb));
	ELSE
		:results.insert(('Good # of APL low level calls','OK',:nb));
	END IF;
	SELECT COUNT(*) into nb FROM "SYS"."AFL_FUNCTION_PARAMETERS" WHERE "AREA_NAME"='APL_AREA';
	-- 821 for master
	-- 796 for cor/pa3.3
	IF :nb <796
	THEN
		:results.insert(('Bad # of descriptions of APL low level calls','ISSUE',:nb));
	ELSE
		:results.insert(('Good # of descriptions of APL low level calls','OK',:nb));
	END IF;

	:results.insert(('Checking registration of high level APL API (APL DU or Hana Cloud SQLAutoContent)',NULL,NULL));
	:results.insert(('____________________________',NULL,NULL));
	IF :is_hce = false
	THEN
		-- dynamic sql because DELIVERY_UNIT table does not exist on HANA Cloud
		EXECUTE IMMEDIATE 'SELECT VERSION FROM "_SYS_REPO"."DELIVERY_UNITS" WHERE DELIVERY_UNIT=''HCO_PA_APL''' INTO du_version;		
		EXECUTE IMMEDIATE 'SELECT LAST_UPDATE FROM "_SYS_REPO"."DELIVERY_UNITS" WHERE DELIVERY_UNIT=''HCO_PA_APL''' INTO du_date;		
		:results.insert(('APL DU Version','',:du_version));
		:results.insert(('APL DU Update date','',du_date));
	END IF;

	SELECT COUNT(*) into nb FROM "ROLES" WHERE "ROLE_NAME" like '%APL%_EXECUTE%';
	IF :nb <>3 
	THEN
		:results.insert(('Bad # of APL roles','ISSUE',:nb));
	ELSE
		:results.insert(('Good # of APL roles','OK',:nb));
	END IF;
	SELECT COUNT(*) into nb FROM "ROLES" WHERE "ROLE_NAME"='sap.pa.apl.base.roles::APL_EXECUTE';
	IF :nb <>1 
	THEN
		:results.insert(('Missing main APL role sap.pa.apl.base.roles::APL_EXECUTE','ISSUE',:nb));
	ELSE
		:results.insert(('Main APL role sap.pa.apl.base.roles::APL_EXECUTE is declared','OK',:nb));
	END IF;
	SELECT COUNT(*) into nb FROM "M_TABLES" WHERE "SCHEMA_NAME" = 'SAP_PA_APL';
	IF :nb < 31
	THEN
		:results.insert(('Bad # of APL artefacts','ISSUE',:nb));
	ELSE
		:results.insert(('Good # of APL artefacts','OK',:nb));
	END IF;
	SELECT COUNT(*) into nb FROM "PUBLIC"."PROCEDURES" WHERE "SCHEMA_NAME" LIKE 'SAP_PA_APL';
	IF :nb <73
	THEN
		:results.insert(('Bad # of high level APL APIs','ISSUE',:nb));
	ELSE
		:results.insert(('Good # of high level APL APIs','OK',:nb));
	END IF;
	-- dynamic SQL because granting this role is done differently
	-- on HANA Cloud or HANA On Premise
	IF :is_hce = true
	THEN
		EXECUTE IMMEDIATE 'GRANT "sap.pa.apl.base.roles::APL_EXECUTE" TO CHECK_APL';
		:results.insert(('grant successful "sap.pa.apl.base.roles::APL_EXECUTE" to CHECK_APL','OK',NULL));
	ELSE
		-- Need to use an exec so it can be compiled even on hana cloud
		-- cannot use new advanced SQLScript features so it can run on HANA 1.2 and HANA 2.0
		EXECUTE IMMEDIATE 'INSERT INTO "CHECK_APL"."COUNT_ACTIVE_OBJECTS" SELECT COUNT(*) FROM "_SYS_REPO"."ACTIVE_OBJECT" AS T1 LEFT OUTER JOIN "_SYS_REPO"."PACKAGE_CATALOG" AS T2 ON T1."PACKAGE_ID" = T2."PACKAGE_ID" WHERE T2."DELIVERY_UNIT"=''HCO_PA_APL'' AND T1."OBJECT_STATUS"= 0';
		SELECT "NB_ACTIVE_OBJECTS" into nb FROM "CHECK_APL"."COUNT_ACTIVE_OBJECTS";	
		IF :nb < 77
		THEN
			:results.insert(('Bad # of activated high level APL APIs: APL DU is not activated','ISSUE',:nb));
		ELSE
			:results.insert(('Good # of activated high level APL APIs: APL DU is activated','OK',:nb));
		END IF;
		EXECUTE IMMEDIATE 'call _SYS_REPO.GRANT_ACTIVATED_ROLE (''sap.pa.apl.base.roles::APL_EXECUTE'',''CHECK_APL'')';
		:results.insert(('GRANT_ACTIVATED_ROLE successful "sap.pa.apl.base.roles::APL_EXECUTE" to CHECK_APL','OK',NULL));
	END IF;
	:results.insert(('Checking installation of APL plugin','Done',NULL));
	:results.insert(('_________________________________',NULL,NULL));
END;


CREATE PROCEDURE "CHECK_APL"."SHAKE_APL_RUNTIME"(OUT results "CHECK_APL"."CHECK_RESULTS_T", OUT ping_results "CHECK_APL"."CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE nb INTEGER;
	DECLARE nb_min INTEGER;
	DECLARE is_hce BOOLEAN = "CHECK_APL"."IS_HCE"();
	DECLARE ping_proc "CHECK_APL"."PING_OUTPUT_T";
	DECLARE ping_direct "CHECK_APL"."PING_OUTPUT_T";
	DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:results.insert(('SHAKE_APL_RUNTIME SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
	END;
	:results.insert(('Checking APL basic run time',NULL,NULL));
	:results.insert(('____________________________',NULL,NULL));

	:results.insert(('Checking PING (proc mode)',NULL,NULL));
	-- use an exec so this code can be compiled by SYSTEM
	EXECUTE IMMEDIATE 'CALL "SAP_PA_APL"."sap.pa.apl.base::PING"(:ping_proc)' into ping_proc;
	:results.insert(('Calling proc PING successful','OK',NULL));
	ping_results = SELECT "name" AS "KEY",NULL AS "STATUS","value" AS "DETAILS" FROM :ping_proc;
	:results.insert(('Analyzing results of PING',NULL,NULL));
	SELECT COUNT(*) into nb FROM :ping_proc;
	if :is_hce=TRUE
	THEN
		NB_MIN = 21; 
	ELSE
		NB_MIN = 17;
	END IF;
	IF :nb < :NB_MIN
	THEN
		:results.insert(('Issue: proc ping results should be at least ' || :NB_MIN || ' rows and are actually','ISSUE',:nb));
	ELSE
		:results.insert(('proc PING results looks like OK','OK',:nb));	
	END IF;
	IF :is_hce=true 
	THEN
		SELECT COUNT(*) into nb FROM :ping_proc WHERE "name" LIKE 'SQLAutoContent%';
		if :nb <>3
		THEN
			:results.insert(('Issue: HCE marker tags in proc PING results should be 3 and are actually','ISSUE',:nb));
		ELSE
			:results.insert(('Found HCE tags in proc PING results','OK',:nb));		
		END IF;
	END IF;
	:results.insert(('____________________________',NULL,NULL));

	:results.insert(('Checking PING (direct mode)',NULL,NULL));
	-- use an exec so this code can be compiled  by SYSTEM
	EXECUTE IMMEDIATE 'CALL _SYS_AFL.APL_AREA_PING_PROC(:ping_direct)' into ping_direct;
	:results.insert(('Calling direct PING successful','OK',NULL));
	:results.insert(('Analyzing results of PING',NULL,NULL));
	SELECT COUNT(*) into nb FROM :ping_direct;
	IF :nb < 17
	THEN
		:results.insert(('Issue: direct ping results should be at least 17 rows and are actually','ISSUE',:nb));
	ELSE
		:results.insert(('direct PING results looks like OK','OK',:nb));	
	END IF;
	:results.insert(('Checking APL basic run time','Done',NULL));
	:results.insert(('____________________________',NULL,NULL));
END;






CREATE PROCEDURE "CHECK_APL"."ANALYZE_CHECKS"(
	IN check_results "CHECK_APL"."CHECK_RESULTS_T",
	OUT FinalResults "CHECK_APL"."CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE nb_issues INTEGER = 0;
	DECLARE nb_fatal_errors INTEGER = 0;
	DECLARE check_install_ended INTEGER = 0;
	DECLARE check_basic_runtime_ended INTEGER = 0;
	DECLARE check_deployment_issue_ended INTEGER = 0;
	DECLARE check_train_ended INTEGER = 0;
	DECLARE check_apply_ended INTEGER = 0;
	DECLARE error_message NVARCHAR(5000) = NULL;
	DECLARE apl_ok NVARCHAR(5000) = 'OK';
	DECLARE issues "CHECK_APL"."CHECK_RESULTS_T";
	DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:FinalResults.insert(('ANALYZE_CHECKS SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
	END;

	IF IS_EMPTY(:check_results) 
	THEN
		RETURN;
	END IF;

	SELECT COUNT(*) into nb_issues FROM :check_results WHERE "STATUS"='ISSUE';
	SELECT COUNT(*) into check_basic_runtime_ended FROM :check_results WHERE "KEY" = 'Checking APL basic run time' AND "STATUS" ='Done';
	SELECT COUNT(*) into check_deployment_issue_ended FROM :check_results WHERE "KEY" = 'Checking deployment issues of APL plugin' AND "STATUS" ='Done';
	SELECT COUNT(*) into check_train_ended FROM :check_results WHERE "KEY" = 'Checking train in procedure mode' AND "STATUS" ='Done';
	SELECT COUNT(*) into check_apply_ended FROM :check_results WHERE "KEY" = 'Checking apply in procedure mode' AND "STATUS" ='Done';
	SELECT COUNT(*) into check_install_ended FROM :check_results WHERE "KEY"='Checking installation of APL plugin' AND "STATUS" ='Done';
	if check_install_ended=1
	then
		 :FinalResults.insert(('Analysis of install of APL plugin properly ended','OK',NULL));
	else
		SELECT Details into error_message FROM :check_results WHERE "KEY"='SHAKE_APL_INSTALL SQLScript error:' LIMIT 1 ;
		:FinalResults.insert(('Analysis of install of APL plugin unexpectedly ended','ERROR','Reported failure is ' || :error_message)  );
		apl_ok = 'ERROR';
	end if; 
	if check_basic_runtime_ended=1
	then
		:FinalResults.insert(('Analysis of APL basic runtime properly ended','OK',NULL));
	else
		SELECT details into error_message FROM :check_results WHERE "KEY"='SHAKE_APL_RUNTIME SQLScript error:' LIMIT 1;
		:FinalResults.insert(('Analysis of APL basic runtime unexpectedly ended','ERROR','Reported failure is ' || :error_message)  );
		apl_ok = 'ERROR';
	end if;
	if check_deployment_issue_ended=1
	then
		:FinalResults.insert(('Analysis of APL deployment issue properly ended','OK',NULL));
	else
		SELECT details into error_message FROM :check_results WHERE "KEY"='SHAKE_APL_STRANGE_ISSUES SQLScript error:' LIMIT 1;
		:FinalResults.insert(('Analysis of APL deploiement issue unexpectedly ended','ERROR','Reported failure is ' || :error_message)  );
		apl_ok = 'ERROR';
	end if;
	if check_train_ended=1
	then
		:FinalResults.insert(('Analysis of APL train properly ended','OK',NULL));
	else
		SELECT details into error_message FROM :check_results WHERE "KEY"='SHAKE_TRAIN_PROCEDURE_MODE SQLScript error:' LIMIT 1;
		:FinalResults.insert(('Analysis of APL train unexpectedly ended','ERROR','Reported failure is ' || :error_message)  );
		apl_ok = 'ERROR';
	end if;
	if check_apply_ended=1
	then
		:FinalResults.insert(('Analysis of APL apply properly ended','OK',NULL));
	else
		SELECT details into error_message FROM :check_results WHERE "KEY"='SHAKE_APPLY_PROCEDURE_MODE SQLScript error:' LIMIT 1;
		:FinalResults.insert(('Analysis of APL apply unexpectedly ended','ERROR','Reported failure is ' || :error_message)  );
		apl_ok = 'ERROR';
	end if;


	if :apl_ok <>'OK'
	then
		:FinalResults.insert(('All tests were not done. List of detected issues is therefore not complete',NULL,NULL));
	else
		:FinalResults.insert(('All tests were done. List of detected issues is supposed to be complete',NULL,NULL));
	end if;
	
	if :nb_issues > 0
	then
		:FinalResults.insert(('There are ' || :nb_issues ||' detected issues in APL install or runtime','ERROR','Please provide this log to support'));
		issues = SELECT * FROM :check_results WHERE "STATUS"='ISSUE';
		:FinalResults.insert(:issues);
		apl_ok = 'ERROR';
	else
		:FinalResults.insert(('No issue detected in APL install/runtime','OK',NULL));
	end if;
END;



CREATE PROCEDURE "CHECK_APL"."SHAKE_APL_STRANGE_ISSUES"(OUT results "CHECK_APL"."CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE is_hce BOOLEAN = "CHECK_APL"."IS_HCE"();
	DECLARE apl_apis_available INTEGER;
	DECLARE effective_apl_apis_available INTEGER;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:results.insert(('SHAKE_APL_STRANGE_ISSUES SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
	END;

	:results.insert(('Checking deployment issues of APL plugin',NULL,NULL));
	:results.insert(('____________________________',NULL,NULL));
	-- Looks like the meaning of EFFECTIVE_PRIVILEGES is not the same on HANA Cloud
	-- actual values for OBJECT_NAMES are very different for On Premise ..
	-- So the check is done only for HANA On Premise
	if :is_hce = False
	then
		SELECT COUNT(*) into effective_apl_apis_available FROM "PUBLIC"."EFFECTIVE_PRIVILEGES" 
		WHERE "USER_NAME"='CHECK_APL'
		AND "SCHEMA_NAME"='SAP_PA_APL'
		AND "GRANTEE"='sap.pa.apl.base.roles::APL_EXECUTE'
		AND ("OBJECT_TYPE"='PROCEDURE'  OR "OBJECT_TYPE"='FUNCTION')
		AND "OBJECT_NAME" NOT LIKE 'APL%' 
		AND "OBJECT_NAME" IN (
			SELECT "PROCEDURE_NAME" FROM "SYS"."PROCEDURES" WHERE "SCHEMA_NAME"='SAP_PA_APL' AND "PROCEDURE_NAME" NOT LIKE 'APL%'
			UNION
			SELECT "FUNCTION_NAME" FROM "SYS"."FUNCTIONS" WHERE "SCHEMA_NAME"='SAP_PA_APL' AND "FUNCTION_NAME" NOT LIKE 'APL%'
			);
		SELECT COUNT(*) into apl_apis_available FROM (
			SELECT "PROCEDURE_NAME" FROM "SYS"."PROCEDURES" WHERE "SCHEMA_NAME"='SAP_PA_APL' AND "PROCEDURE_NAME" NOT LIKE 'APL%'
			UNION
			SELECT "FUNCTION_NAME" FROM "SYS"."FUNCTIONS" WHERE "SCHEMA_NAME"='SAP_PA_APL' AND "FUNCTION_NAME" NOT LIKE 'APL%'
			);
		IF :apl_apis_available <> :effective_apl_apis_available
		THEN
			:results.insert(('Effective deployment of APL for user CHECK_APL','ISSUE',:effective_apl_apis_available || '<>' ||:apl_apis_available));
			:results.insert((NULL,'ISSUE','!!! You need to redeploy APL DU using hdbalm !!'));
		ELSE
			:results.insert(('Effective deployment of APL for user CHECK_APL','OK',:apl_apis_available || ' effective APL APIS'));
		END IF;	
	end if;
	:results.insert(('Checking deployment issues of APL plugin','Done',NULL));
	:results.insert(('____________________________',NULL,NULL));
END;


-- Functional tests
-- input table

CREATE TYPE "CHECK_APL"."SMALL_ADULT_T" AS TABLE (
	 "age" INTEGER,
	 "workclass" NVARCHAR(32),
	 "fnlwgt" INTEGER,
	 "education" NVARCHAR(32),
	 "education-num" INTEGER,
	 "marital-status" NVARCHAR(32),
	 "occupation" NVARCHAR(32),
	 "relationship" NVARCHAR(32),
	 "race" NVARCHAR(32),
	 "sex" NVARCHAR(16),
	 "capital-gain" INTEGER,
	 "capital-loss" INTEGER,
	 "hours-per-week" INTEGER,
	 "native-country" NVARCHAR(32),
	 "class" INTEGER);

CREATE COLUMN TABLE "CHECK_APL"."SMALL_ADULT" LIKE "CHECK_APL"."SMALL_ADULT_T";


-- These tests must be done now as SYSTEM
-- because as part of action,they will grant on the fly proper rights
--  so further code can be compiled as CHECK_APL

DO BEGIN
	DECLARE prerequisite_results "CHECK_APL"."CHECK_RESULTS_T";
	DECLARE install_results "CHECK_APL"."CHECK_RESULTS_T";
	DECLARE strange_issues_results "CHECK_APL"."CHECK_RESULTS_T";
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION	
	BEGIN
		:install_results.insert(('RUN_TESTS_STEP1 SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
	END;

	IF "CHECK_APL"."IS_HCE"() = FALSE 
	THEN
		:prerequisite_results.insert(('===== HANA On Premise !! =====',NULL,NULL));
	ELSE
		:prerequisite_results.insert(('===== HANA Cloud !! =====',NULL,NULL));
	END IF;

	IF "CHECK_APL"."HAS_APL"() = FALSE 
	THEN
		:prerequisite_results.insert(('===== APL is NOT installed !! =====','ISSUE',NULL));
	ELSE
		:prerequisite_results.insert(('===== APL is installed !! =====','OK',NULL));		
	END IF;
	search_scriptserver = SELECT * FROM "M_SERVICES" WHERE "SERVICE_NAME" = 'scriptserver';
	IF "CHECK_APL"."HAS_SCRIPTSERVER"() = FALSE 
	THEN
		:prerequisite_results.insert(('===== Script Server is not activated !! =====','ISSUE','APL even if installed, cannot be called!'));
	ELSE
		:prerequisite_results.insert(('===== Script Server is activated !! =====','OK',NULL));
	END IF;
	INSERT INTO "CHECK_APL"."APL_CHECK_RESULTS" SELECT * FROM :prerequisite_results;
	
	IF "CHECK_APL"."HAS_APL"() = TRUE
	THEN
		CALL "CHECK_APL"."SHAKE_APL_INSTALL"(:install_results);
		INSERT INTO "CHECK_APL"."APL_CHECK_RESULTS" SELECT * FROM :install_results;
		CALL "CHECK_APL"."SHAKE_APL_STRANGE_ISSUES"(:strange_issues_results);
		INSERT INTO "CHECK_APL"."APL_CHECK_RESULTS" SELECT * FROM :strange_issues_results;
	END IF;
END;


-- Prepare code as CHECK_APL

connect CHECK_APL PASSWORD &CHECK_APL_PASSWORD;

CREATE PROCEDURE "CHECK_APL"."SHAKE_TRAIN_PROCEDURE_MODE"(OUT model "CHECK_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID",OUT results "CHECK_APL"."CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN 
	DECLARE NbSmallAdult INTEGER;
	DECLARE config "CHECK_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
	DECLARE header "CHECK_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
	DECLARE var_role "CHECK_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
	DECLARE var_desc "CHECK_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
	DECLARE out_log "CHECK_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";
	DECLARE out_sum "CHECK_APL"."sap.pa.apl.base::BASE.T.SUMMARY";
	DECLARE out_indic "CHECK_APL"."sap.pa.apl.base::BASE.T.INDICATORS";
	DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:results.insert(('SHAKE_TRAIN_PROCEDURE_MODE SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
	END;
	:results.insert(('Checking train in procedure mode',NULL,NULL));
	:results.insert(('____________________________',NULL,NULL));

	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (39,'State-gov',77516,'Bachelors',13,'Never married','Adm-clerical','Not-in-family','White','Male',2174,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (50,'Self-emp-not-inc',83311,'Bachelors',13,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,13,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Private',215646,'HS-grad',9,'Divorced','Handlers-cleaners','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (53,'Private',234721,'11th',7,'Married civ spouse','Handlers-cleaners','Husband','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'Private',338409,'Bachelors',13,'Married civ spouse','Prof-specialty','Wife','Black','Female',0,0,40,'Cuba',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (37,'Private',284582,'Masters',14,'Married civ spouse','Exec managerial','Wife','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (49,'Private',160187,'9th',5,'Married-spouse-absent','Other-service','Not-in-family','Black','Female',0,0,16,'Jamaica',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (52,'Self-emp-not-inc',209642,'HS-grad',9,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,45,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'Private',45781,'Masters',14,'Never married','Prof-specialty','Not-in-family','White','Female',14084,0,50,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (42,'Private',159449,'Bachelors',13,'Married civ spouse','Exec managerial','Husband','White','Male',5178,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (37,'Private',280464,'Some-college',10,'Married civ spouse','Exec managerial','Husband','Black','Male',0,0,80,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'State-gov',141297,'Bachelors',13,'Married civ spouse','Prof-specialty','Husband','Asian-Pac-Islander','Male',0,0,40,'India',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,'Private',122272,'Bachelors',13,'Never married','Adm-clerical','Own-child','White','Female',0,0,30,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (32,'Private',205019,'Assoc-acdm',12,'Never married','Sales','Not-in-family','Black','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'Private',121772,'Assoc-voc',11,'Married civ spouse','Craft-repair','Husband','Asian-Pac-Islander','Male',0,0,40,NULL,1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'Private',245487,'7th-8th',4,'Married civ spouse','Transport-moving','Husband','Amer-Indian-Eskimo','Male',0,0,45,'Mexico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (25,'Self-emp-not-inc',176756,'HS-grad',9,'Never married','Farming-fishing','Own-child','White','Male',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (32,'Private',186824,'HS-grad',9,'Never married','Machine-op-inspct','Unmarried','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Private',28887,'11th',7,'Married civ spouse','Sales','Husband','White','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Self-emp-not-inc',292175,'Masters',14,'Divorced','Exec managerial','Unmarried','White','Female',0,0,45,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'Private',193524,'Doctorate',16,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,60,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (54,'Private',302146,'HS-grad',9,'Separated','Other-service','Unmarried','Black','Female',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,'Federal-gov',76845,'9th',5,'Married civ spouse','Farming-fishing','Husband','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Private',117037,'11th',7,'Married civ spouse','Transport-moving','Husband','White','Male',0,2042,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (59,'Private',109015,'HS-grad',9,'Divorced','Tech-support','Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (56,'Local-gov',216851,'Bachelors',13,'Married civ spouse','Tech-support','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (19,'Private',168294,'HS-grad',9,'Never married','Craft-repair','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (54,NULL,180211,'Some-college',10,'Married civ spouse',NULL,'Husband','Asian-Pac-Islander','Male',0,0,60,'South',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (39,'Private',367260,'HS-grad',9,'Divorced','Exec managerial','Not-in-family','White','Male',0,0,80,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (49,'Private',193366,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,'Local-gov',190709,'Assoc-acdm',12,'Never married','Protective-serv','Not-in-family','White','Male',0,0,52,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (20,'Private',266015,'Some-college',10,'Never married','Sales','Own-child','Black','Male',0,0,44,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (45,'Private',386940,'Bachelors',13,'Divorced','Exec managerial','Own-child','White','Male',0,1408,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Federal-gov',59951,'Some-college',10,'Married civ spouse','Adm-clerical','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (22,'State-gov',311512,'Some-college',10,'Married civ spouse','Other-service','Husband','Black','Male',0,0,15,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (48,'Private',242406,'11th',7,'Never married','Machine-op-inspct','Unmarried','White','Male',0,0,40,'Puerto-Rico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (21,'Private',197200,'Some-college',10,'Never married','Machine-op-inspct','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (19,'Private',544091,'HS-grad',9,'Married-AF-spouse','Adm-clerical','Wife','White','Female',0,0,25,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'Private',84154,'Some-college',10,'Married civ spouse','Sales','Husband','White','Male',0,0,38,NULL,1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (48,'Self-emp-not-inc',265477,'Assoc-acdm',12,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'Private',507875,'9th',5,'Married civ spouse','Machine-op-inspct','Husband','White','Male',0,0,43,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (53,'Self-emp-not-inc',88506,'Bachelors',13,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (24,'Private',172987,'Bachelors',13,'Married civ spouse','Tech-support','Husband','White','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (49,'Private',94638,'HS-grad',9,'Separated','Adm-clerical','Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (25,'Private',289980,'HS-grad',9,'Never married','Handlers-cleaners','Not-in-family','White','Male',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (57,'Federal-gov',337895,'Bachelors',13,'Married civ spouse','Prof-specialty','Husband','Black','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (53,'Private',144361,'HS-grad',9,'Married civ spouse','Machine-op-inspct','Husband','White','Male',0,0,38,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Private',128354,'Masters',14,'Divorced','Exec managerial','Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'State-gov',101603,'Assoc-voc',11,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (29,'Private',271466,'Assoc-voc',11,'Never married','Prof-specialty','Not-in-family','White','Male',0,0,43,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (25,'Private',32275,'Some-college',10,'Married civ spouse','Exec managerial','Wife','Other','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (18,'Private',226956,'HS-grad',9,'Never married','Other-service','Own-child','White','Female',0,0,30,NULL,0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (47,'Private',51835,'Prof-school',15,'Married civ spouse','Prof-specialty','Wife','White','Female',0,1902,60,'Honduras',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (50,'Federal-gov',251585,'Bachelors',13,'Divorced','Exec managerial','Not-in-family','White','Male',0,0,55,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (47,'Self-emp-inc',109832,'HS-grad',9,'Divorced','Exec managerial','Not-in-family','White','Male',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Private',237993,'Some-college',10,'Married civ spouse','Tech-support','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'Private',216666,'5th-6th',3,'Married civ spouse','Machine-op-inspct','Husband','White','Male',0,0,40,'Mexico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,'Private',56352,'Assoc-voc',11,'Married civ spouse','Other-service','Husband','White','Male',0,0,40,'Puerto-Rico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Private',147372,'HS-grad',9,'Married civ spouse','Adm-clerical','Husband','White','Male',0,0,48,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',188146,'HS-grad',9,'Married civ spouse','Machine-op-inspct','Husband','White','Male',5013,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',59496,'Bachelors',13,'Married civ spouse','Sales','Husband','White','Male',2407,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (32,NULL,293936,'7th-8th',4,'Married-spouse-absent',NULL,'Not-in-family','White','Male',0,0,40,NULL,0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (48,'Private',149640,'HS-grad',9,'Married civ spouse','Transport-moving','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (42,'Private',116632,'Doctorate',16,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,45,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (29,'Private',105598,'Some-college',10,'Divorced','Tech-support','Not-in-family','White','Male',0,0,58,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (36,'Private',155537,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'Private',183175,'Some-college',10,'Divorced','Adm-clerical','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (53,'Private',169846,'HS-grad',9,'Married civ spouse','Adm-clerical','Wife','White','Female',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (49,'Self-emp-inc',191681,'Some-college',10,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,50,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (25,NULL,200681,'Some-college',10,'Never married',NULL,'Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (19,'Private',101509,'Some-college',10,'Never married','Prof-specialty','Own-child','White','Male',0,0,32,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'Private',309974,'Bachelors',13,'Separated','Sales','Own-child','Black','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (29,'Self-emp-not-inc',162298,'Bachelors',13,'Married civ spouse','Sales','Husband','White','Male',0,0,70,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,'Private',211678,'Some-college',10,'Never married','Machine-op-inspct','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (79,'Private',124744,'Some-college',10,'Married civ spouse','Prof-specialty','Other-relative','White','Male',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (27,'Private',213921,'HS-grad',9,'Never married','Other-service','Own-child','White','Male',0,0,40,'Mexico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'Private',32214,'Assoc-acdm',12,'Married civ spouse','Adm-clerical','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (67,NULL,212759,'10th',6,'Married civ spouse',NULL,'Husband','White','Male',0,0,2,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (18,'Private',309634,'11th',7,'Never married','Other-service','Own-child','White','Female',0,0,22,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'Local-gov',125927,'7th-8th',4,'Married civ spouse','Farming-fishing','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (18,'Private',446839,'HS-grad',9,'Never married','Sales','Not-in-family','White','Male',0,0,30,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (52,'Private',276515,'Bachelors',13,'Married civ spouse','Other-service','Husband','White','Male',0,0,40,'Cuba',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'Private',51618,'HS-grad',9,'Married civ spouse','Other-service','Wife','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (59,'Private',159937,'HS-grad',9,'Married civ spouse','Sales','Husband','White','Male',0,0,48,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Private',343591,'HS-grad',9,'Divorced','Craft-repair','Not-in-family','White','Female',14344,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (53,'Private',346253,'HS-grad',9,'Divorced','Sales','Own-child','White','Female',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (49,'Local-gov',268234,'HS-grad',9,'Married civ spouse','Protective-serv','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',202051,'Masters',14,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',54334,'9th',5,'Never married','Sales','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Federal-gov',410867,'Doctorate',16,'Never married','Prof-specialty','Not-in-family','White','Female',0,0,50,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (57,'Private',249977,'Assoc-voc',11,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (37,'Private',286730,'Some-college',10,'Divorced','Craft-repair','Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'Private',212563,'Some-college',10,'Divorced','Machine-op-inspct','Unmarried','Black','Female',0,0,25,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',117747,'HS-grad',9,'Married civ spouse','Sales','Wife','Asian-Pac-Islander','Female',0,1573,35,NULL,0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'Local-gov',226296,'Bachelors',13,'Married civ spouse','Protective-serv','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (29,'Local-gov',115585,'Some-college',10,'Never married','Handlers-cleaners','Not-in-family','White','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (48,'Self-emp-not-inc',191277,'Doctorate',16,'Married civ spouse','Prof-specialty','Husband','White','Male',0,1902,60,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (37,'Private',202683,'Some-college',10,'Married civ spouse','Sales','Husband','White','Male',0,0,48,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (48,'Private',171095,'Assoc-acdm',12,'Divorced','Exec managerial','Unmarried','White','Female',0,0,40,'England',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (32,'Federal-gov',249409,'HS-grad',9,'Never married','Other-service','Own-child','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (76,'Private',124191,'Masters',14,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Private',198282,'Bachelors',13,'Married civ spouse','Exec managerial','Husband','White','Male',15024,0,60,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (47,'Self-emp-not-inc',149116,'Masters',14,'Never married','Prof-specialty','Not-in-family','White','Female',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (20,'Private',188300,'Some-college',10,'Never married','Tech-support','Own-child','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (29,'Private',103432,'HS-grad',9,'Never married','Craft-repair','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (32,'Self-emp-inc',317660,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','White','Male',7688,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (17,NULL,304873,'10th',6,'Never married',NULL,'Own-child','White','Female',34095,0,32,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',194901,'11th',7,'Never married','Handlers-cleaners','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'Local-gov',189265,'HS-grad',9,'Never married','Adm-clerical','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (42,'Private',124692,'HS-grad',9,'Married civ spouse','Handlers-cleaners','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (24,'Private',432376,'Bachelors',13,'Never married','Sales','Other-relative','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Private',65324,'Prof-school',15,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (56,'Self-emp-not-inc',335605,'HS-grad',9,'Married civ spouse','Other-service','Husband','White','Male',0,1887,50,'Canada',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'Private',377869,'Some-college',10,'Married civ spouse','Sales','Wife','White','Female',4064,0,25,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (36,'Private',102864,'HS-grad',9,'Never married','Machine-op-inspct','Own-child','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (53,'Private',95647,'9th',5,'Married civ spouse','Handlers-cleaners','Husband','White','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (56,'Self-emp-inc',303090,'Some-college',10,'Married civ spouse','Sales','Husband','White','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (49,'Local-gov',197371,'Assoc-voc',11,'Married civ spouse','Craft-repair','Husband','Black','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (55,'Private',247552,'Some-college',10,'Married civ spouse','Sales','Husband','White','Male',0,0,56,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (22,'Private',102632,'HS-grad',9,'Never married','Craft-repair','Not-in-family','White','Male',0,0,41,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (21,'Private',199915,'Some-college',10,'Never married','Other-service','Own-child','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'Private',118853,'Bachelors',13,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',77143,'Bachelors',13,'Never married','Exec managerial','Own-child','Black','Male',0,0,40,'Germany',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (29,'State-gov',267989,'Bachelors',13,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,50,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (19,'Private',301606,'Some-college',10,'Never married','Other-service','Own-child','Black','Male',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (47,'Private',287828,'Bachelors',13,'Married civ spouse','Exec managerial','Wife','White','Female',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (20,'Private',111697,'Some-college',10,'Never married','Adm-clerical','Own-child','White','Female',0,1719,28,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'Private',114937,'Assoc-acdm',12,'Married civ spouse','Adm-clerical','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,NULL,129305,'HS-grad',9,'Married civ spouse',NULL,'Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (39,'Private',365739,'Some-college',10,'Divorced','Craft-repair','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'Private',69621,'Assoc-acdm',12,'Never married','Sales','Not-in-family','White','Female',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (24,'Private',43323,'HS-grad',9,'Never married','Other-service','Not-in-family','White','Female',0,1762,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Self-emp-not-inc',120985,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','White','Male',4386,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (37,'Private',254202,'Bachelors',13,'Married civ spouse','Sales','Husband','White','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'Private',146195,'Assoc-acdm',12,'Divorced','Tech-support','Not-in-family','Black','Female',0,0,36,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Federal-gov',125933,'Masters',14,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,40,'Iran',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Self-emp-not-inc',56920,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (27,'Private',163127,'Assoc-voc',11,'Married civ spouse','Adm-clerical','Wife','White','Female',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (20,'Private',34310,'Some-college',10,'Never married','Sales','Own-child','White','Male',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (49,'Private',81973,'Some-college',10,'Married civ spouse','Craft-repair','Husband','Asian-Pac-Islander','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (61,'Self-emp-inc',66614,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (27,'Private',232782,'Some-college',10,'Never married','Sales','Own-child','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (19,'Private',316868,'Some-college',10,'Never married','Other-service','Own-child','White','Male',0,0,30,'Mexico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (45,'Private',196584,'Assoc-voc',11,'Never married','Prof-specialty','Not-in-family','White','Female',0,1564,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (70,'Private',105376,'Some-college',10,'Never married','Tech-support','Other-relative','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'Private',185814,'HS-grad',9,'Never married','Transport-moving','Unmarried','Black','Female',0,0,30,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (22,'Private',175374,'Some-college',10,'Married civ spouse','Other-service','Husband','White','Male',0,0,24,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (36,'Private',108293,'HS-grad',9,'Widowed','Other-service','Unmarried','White','Female',0,0,24,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (64,'Private',181232,'11th',7,'Married civ spouse','Craft-repair','Husband','White','Male',0,2179,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,NULL,174662,'Some-college',10,'Divorced',NULL,'Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (47,'Local-gov',186009,'Some-college',10,'Divorced','Adm-clerical','Unmarried','White','Female',0,0,38,'Mexico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'Private',198183,'HS-grad',9,'Never married','Adm-clerical','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',163003,'Bachelors',13,'Never married','Exec managerial','Other-relative','Asian-Pac-Islander','Female',0,0,40,'Philippines',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (21,'Private',296158,'HS-grad',9,'Never married','Craft-repair','Own-child','White','Male',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (52,NULL,252903,'HS-grad',9,'Divorced',NULL,'Not-in-family','White','Male',0,0,45,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (48,'Private',187715,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,46,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,'Private',214542,'Bachelors',13,'Never married','Handlers-cleaners','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (71,'Self-emp-not-inc',494223,'Some-college',10,'Separated','Sales','Unmarried','Black','Male',0,1816,2,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (29,'Private',191535,'HS-grad',9,'Divorced','Craft-repair','Not-in-family','White','Male',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (42,'Private',228456,'Bachelors',13,'Separated','Other-service','Other-relative','Black','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (68,NULL,38317,'1st-4th',2,'Divorced',NULL,'Not-in-family','White','Female',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (25,'Private',252752,'HS-grad',9,'Never married','Other-service','Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Self-emp-inc',78374,'Masters',14,'Divorced','Exec managerial','Unmarried','Asian-Pac-Islander','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'Private',88419,'HS-grad',9,'Never married','Exec managerial','Not-in-family','Asian-Pac-Islander','Female',0,0,40,'England',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (45,'Self-emp-not-inc',201080,'Masters',14,'Married civ spouse','Sales','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (36,'Private',207157,'Some-college',10,'Divorced','Other-service','Unmarried','White','Female',0,0,40,'Mexico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (39,'Federal-gov',235485,'Assoc-acdm',12,'Never married','Exec managerial','Not-in-family','White','Male',0,0,42,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'State-gov',102628,'Masters',14,'Widowed','Protective-serv','Unmarried','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (18,'Private',25828,'11th',7,'Never married','Handlers-cleaners','Own-child','White','Male',0,0,16,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (66,'Local-gov',54826,'Assoc-voc',11,'Widowed','Prof-specialty','Not-in-family','White','Female',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (27,'Private',124953,'HS-grad',9,'Never married','Other-service','Not-in-family','White','Male',0,1980,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'State-gov',175325,'HS-grad',9,'Married civ spouse','Protective-serv','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (51,'Private',96062,'Some-college',10,'Married civ spouse','Sales','Husband','White','Male',0,1977,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (27,'Private',428030,'Bachelors',13,'Never married','Craft-repair','Not-in-family','White','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'State-gov',149624,'Bachelors',13,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (27,'Private',253814,'HS-grad',9,'Married-spouse-absent','Sales','Unmarried','White','Female',0,0,25,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (21,'Private',312956,'HS-grad',9,'Never married','Craft-repair','Own-child','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'Private',483777,'HS-grad',9,'Never married','Handlers-cleaners','Not-in-family','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (18,'Private',183930,'HS-grad',9,'Never married','Other-service','Own-child','White','Male',0,0,12,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',37274,'Bachelors',13,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,65,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Local-gov',181344,'Some-college',10,'Married civ spouse','Exec managerial','Husband','Black','Male',0,0,38,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Private',114580,'Some-college',10,'Divorced','Adm-clerical','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',633742,'Some-college',10,'Never married','Craft-repair','Not-in-family','Black','Male',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'Private',286370,'7th-8th',4,'Married civ spouse','Machine-op-inspct','Husband','White','Male',0,0,40,'Mexico',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (37,'Federal-gov',29054,'Some-college',10,'Married civ spouse','Adm-clerical','Husband','White','Male',0,0,42,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'Private',304030,'HS-grad',9,'Married civ spouse','Adm-clerical','Husband','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Self-emp-not-inc',143129,'Bachelors',13,'Divorced','Exec managerial','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (53,NULL,135105,'Bachelors',13,'Divorced',NULL,'Not-in-family','White','Female',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'Private',99928,'Masters',14,'Married civ spouse','Prof-specialty','Wife','White','Female',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (58,'State-gov',109567,'Doctorate',16,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,1,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Private',155222,'Some-college',10,'Divorced','Machine-op-inspct','Not-in-family','Black','Female',0,0,28,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (24,'Private',159567,'Some-college',10,'Married civ spouse','Machine-op-inspct','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Local-gov',523910,'Bachelors',13,'Married civ spouse','Craft-repair','Husband','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (47,'Private',120939,'Some-college',10,'Married civ spouse','Tech-support','Husband','White','Male',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Federal-gov',130760,'Bachelors',13,'Married civ spouse','Tech-support','Husband','White','Male',0,0,24,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,'Private',197387,'5th-6th',3,'Married civ spouse','Transport-moving','Other-relative','White','Male',0,0,40,'Mexico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (36,'Private',99374,'Some-college',10,'Divorced','Craft-repair','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'Federal-gov',56795,'Masters',14,'Never married','Exec managerial','Not-in-family','White','Female',14084,0,55,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,'Private',138992,'Masters',14,'Married civ spouse','Prof-specialty','Other-relative','White','Male',7298,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (24,'Self-emp-not-inc',32921,'HS-grad',9,'Never married','Sales','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (26,'Private',397317,'Masters',14,'Never married','Prof-specialty','Not-in-family','White','Female',0,1876,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (19,NULL,170653,'HS-grad',9,'Never married',NULL,'Own-child','White','Male',0,0,40,'Italy',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (51,'Private',259323,'Bachelors',13,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,50,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (42,'Local-gov',254817,'Some-college',10,'Never married','Prof-specialty','Not-in-family','White','Female',0,1340,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (37,'State-gov',48211,'HS-grad',9,'Divorced','Adm-clerical','Unmarried','White','Female',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (18,'Private',140164,'11th',7,'Never married','Sales','Own-child','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (36,'Private',128757,'Bachelors',13,'Married civ spouse','Other-service','Husband','Black','Male',7298,0,36,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,'Private',36270,'HS-grad',9,'Divorced','Craft-repair','Not-in-family','White','Male',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (58,'Self-emp-inc',210563,'HS-grad',9,'Married civ spouse','Sales','Wife','White','Female',15024,0,35,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (17,'Private',65368,'11th',7,'Never married','Sales','Own-child','White','Female',0,0,12,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Local-gov',160943,'HS-grad',9,'Married civ spouse','Transport-moving','Husband','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (37,'Private',208358,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,'Private',153790,'Some-college',10,'Never married','Sales','Not-in-family','Amer-Indian-Eskimo','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (60,'Private',85815,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','Asian-Pac-Islander','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (54,'Self-emp-inc',125417,'7th-8th',4,'Married civ spouse','Machine-op-inspct','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (37,'Private',635913,'Bachelors',13,'Never married','Exec managerial','Not-in-family','Black','Male',0,0,60,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (50,'Private',313321,'Assoc-acdm',12,'Divorced','Sales','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Private',182609,'Bachelors',13,'Married civ spouse','Sales','Husband','White','Male',0,0,50,'Poland',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (45,'Private',109434,'Bachelors',13,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,55,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (25,'Private',255004,'10th',6,'Never married','Craft-repair','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'Private',197860,'Some-college',10,'Married civ spouse','Handlers-cleaners','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (64,NULL,187656,'1st-4th',2,'Divorced',NULL,'Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (90,'Private',51744,'HS-grad',9,'Never married','Other-service','Not-in-family','Black','Male',0,2206,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (54,'Private',176681,'HS-grad',9,'Married civ spouse','Adm-clerical','Husband','Black','Male',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (53,'Local-gov',140359,'Preschool',1,'Never married','Machine-op-inspct','Not-in-family','White','Female',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (18,'Private',243313,'HS-grad',9,'Never married','Sales','Own-child','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (60,NULL,24215,'10th',6,'Divorced',NULL,'Not-in-family','Amer-Indian-Eskimo','Female',0,0,10,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (66,'Self-emp-not-inc',167687,'HS-grad',9,'Married civ spouse','Farming-fishing','Husband','White','Male',1409,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (75,'Private',314209,'Assoc-voc',11,'Widowed','Adm-clerical','Not-in-family','White','Female',0,0,20,'Columbia',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (65,'Private',176796,'HS-grad',9,'Divorced','Adm-clerical','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,'Private',538583,'11th',7,'Separated','Transport-moving','Not-in-family','Black','Male',3674,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Private',130408,'HS-grad',9,'Divorced','Sales','Unmarried','Black','Female',0,0,38,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (25,'Private',159732,'Some-college',10,'Never married','Adm-clerical','Not-in-family','White','Male',0,0,42,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',110978,'Some-college',10,'Divorced','Craft-repair','Other-relative','Other','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'Private',76714,'Prof-school',15,'Never married','Prof-specialty','Not-in-family','White','Male',0,0,55,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (59,'State-gov',268700,'HS-grad',9,'Married civ spouse','Other-service','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'State-gov',170525,'Some-college',10,'Never married','Adm-clerical','Not-in-family','White','Female',0,0,38,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Private',180138,'Bachelors',13,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,50,'Iran',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Local-gov',115076,'Masters',14,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,70,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,'Private',115458,'HS-grad',9,'Never married','Transport-moving','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'Private',347890,'Bachelors',13,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Self-emp-not-inc',196001,'HS-grad',9,'Married civ spouse','Other-service','Wife','White','Female',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (24,'State-gov',273905,'Assoc-acdm',12,'Married civ spouse','Protective-serv','Husband','White','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (20,NULL,119156,'Some-college',10,'Never married',NULL,'Own-child','White','Male',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Private',179488,'Some-college',10,'Divorced','Craft-repair','Not-in-family','White','Male',0,1741,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (56,'Private',203580,'HS-grad',9,'Married civ spouse','Adm-clerical','Husband','White','Male',0,0,35,NULL,0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (58,'Private',236596,'HS-grad',9,'Married civ spouse','Adm-clerical','Husband','White','Male',0,0,45,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (32,'Private',183916,'HS-grad',9,'Never married','Other-service','Not-in-family','White','Female',0,0,34,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'Private',207578,'Assoc-acdm',12,'Married civ spouse','Tech-support','Husband','White','Male',0,1977,60,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (45,'Private',153141,'HS-grad',9,'Married civ spouse','Adm-clerical','Husband','White','Male',0,0,40,NULL,0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Private',112763,'Prof-school',15,'Married civ spouse','Prof-specialty','Wife','White','Female',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (42,'Private',390781,'Bachelors',13,'Married civ spouse','Adm-clerical','Wife','Black','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (59,'Local-gov',171328,'10th',6,'Widowed','Other-service','Unmarried','Black','Female',0,0,30,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (19,'Local-gov',27382,'Some-college',10,'Never married','Adm-clerical','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (58,'Private',259014,'Some-college',10,'Never married','Transport-moving','Not-in-family','White','Male',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (42,'Self-emp-not-inc',303044,'HS-grad',9,'Married civ spouse','Farming-fishing','Husband','Asian-Pac-Islander','Male',0,0,40,'Cambodia',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (20,'Private',117789,'HS-grad',9,'Never married','Other-service','Own-child','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (32,'Private',172579,'HS-grad',9,'Separated','Other-service','Not-in-family','White','Female',0,0,30,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (45,'Private',187666,'Assoc-voc',11,'Widowed','Exec managerial','Not-in-family','White','Female',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (50,'Private',204518,'7th-8th',4,'Divorced','Craft-repair','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (36,'Private',150042,'Bachelors',13,'Divorced','Prof-specialty','Own-child','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (45,'Private',98092,'HS-grad',9,'Married civ spouse','Sales','Husband','White','Male',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (17,'Private',245918,'11th',7,'Never married','Other-service','Own-child','White','Male',0,0,12,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (59,'Private',146013,'Some-college',10,'Married civ spouse','Sales','Husband','White','Male',4064,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (26,'Private',378322,'11th',7,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (37,'Self-emp-inc',257295,'Some-college',10,'Married civ spouse','Exec managerial','Husband','Asian-Pac-Islander','Male',0,0,75,'Thailand',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (19,NULL,218956,'Some-college',10,'Never married',NULL,'Own-child','White','Male',0,0,24,'Canada',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (64,'Private',21174,'HS-grad',9,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',185480,'Bachelors',13,'Never married','Prof-specialty','Not-in-family','White','Female',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',222205,'HS-grad',9,'Married civ spouse','Craft-repair','Wife','White','Female',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (61,'Private',69867,'HS-grad',9,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (17,'Private',191260,'9th',5,'Never married','Other-service','Own-child','White','Male',1055,0,24,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (50,'Self-emp-not-inc',30653,'Masters',14,'Married civ spouse','Farming-fishing','Husband','White','Male',2407,0,98,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (27,'Local-gov',209109,'Masters',14,'Never married','Prof-specialty','Own-child','White','Male',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',70377,'HS-grad',9,'Divorced','Prof-specialty','Own-child','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Private',477983,'HS-grad',9,'Married civ spouse','Handlers-cleaners','Husband','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Private',170924,'Some-college',10,'Married civ spouse','Craft-repair','Husband','White','Male',7298,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,'Private',190174,'Some-college',10,'Never married','Exec managerial','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (25,'Private',193787,'Some-college',10,'Never married','Tech-support','Own-child','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (24,'Private',279472,'Some-college',10,'Married civ spouse','Machine-op-inspct','Wife','White','Female',7298,0,48,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (22,'Private',34918,'Bachelors',13,'Never married','Prof-specialty','Not-in-family','White','Female',0,0,15,'Germany',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (42,'Local-gov',97688,'Some-college',10,'Married civ spouse','Craft-repair','Husband','White','Male',5178,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'Private',175413,'Assoc-acdm',12,'Divorced','Sales','Unmarried','Black','Female',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (60,'Private',173960,'Bachelors',13,'Divorced','Prof-specialty','Not-in-family','White','Female',0,0,42,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (21,'Private',205759,'HS-grad',9,'Never married','Handlers-cleaners','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (57,'Federal-gov',425161,'Masters',14,'Married civ spouse','Sales','Husband','White','Male',15024,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Private',220531,'Prof-school',15,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,60,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (50,'Private',176609,'Some-college',10,'Divorced','Other-service','Not-in-family','White','Male',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (25,'Private',371987,'Bachelors',13,'Never married','Exec managerial','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (50,'Private',193884,'7th-8th',4,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,40,'Ecuador',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (36,'Private',200352,'Bachelors',13,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'Private',127595,'HS-grad',9,'Divorced','Prof-specialty','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (29,'Local-gov',220419,'Bachelors',13,'Never married','Protective-serv','Not-in-family','White','Male',0,0,56,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (21,'Private',231931,'Some-college',10,'Never married','Sales','Own-child','White','Male',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (27,'Private',248402,'Bachelors',13,'Never married','Tech-support','Unmarried','Black','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (65,'Private',111095,'HS-grad',9,'Married civ spouse','Transport-moving','Husband','White','Male',0,0,16,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (37,'Self-emp-inc',57424,'Bachelors',13,'Divorced','Sales','Not-in-family','White','Female',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (39,NULL,157443,'Masters',14,'Married civ spouse',NULL,'Wife','Asian-Pac-Islander','Female',3464,0,40,NULL,0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (24,'Private',278130,'HS-grad',9,'Never married','Craft-repair','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Private',169469,'HS-grad',9,'Divorced','Sales','Not-in-family','White','Male',0,0,80,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (48,'Private',146268,'Bachelors',13,'Married civ spouse','Adm-clerical','Husband','White','Male',7688,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (21,'Private',153718,'Some-college',10,'Never married','Other-service','Not-in-family','Asian-Pac-Islander','Female',0,0,25,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'Private',217460,'HS-grad',9,'Married civ spouse','Transport-moving','Husband','White','Male',0,0,45,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (55,'Private',238638,'HS-grad',9,'Married civ spouse','Sales','Husband','White','Male',4386,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (24,'Private',303296,'Some-college',10,'Married civ spouse','Adm-clerical','Wife','Asian-Pac-Islander','Female',0,0,40,'Laos',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Private',173321,'HS-grad',9,'Divorced','Adm-clerical','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (26,'Private',193945,'Assoc-acdm',12,'Never married','Tech-support','Not-in-family','White','Male',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'Private',83082,'Assoc-acdm',12,'Never married','Prof-specialty','Not-in-family','White','Female',0,0,33,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,'Private',193815,'Assoc-acdm',12,'Married civ spouse','Adm-clerical','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Self-emp-inc',34987,'Some-college',10,'Married civ spouse','Farming-fishing','Husband','White','Male',0,0,54,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (26,'Private',59306,'Bachelors',13,'Never married','Sales','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'Private',142897,'Masters',14,'Married civ spouse','Exec managerial','Husband','Asian-Pac-Islander','Male',7298,0,35,'Taiwan',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (19,NULL,860348,'Some-college',10,'Never married',NULL,'Own-child','Black','Female',0,0,25,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (36,'Self-emp-not-inc',205607,'Bachelors',13,'Divorced','Prof-specialty','Not-in-family','Black','Female',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (22,'Private',199698,'Some-college',10,'Never married','Sales','Own-child','White','Male',0,0,15,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (24,'Private',191954,'Some-college',10,'Never married','Machine-op-inspct','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (77,'Self-emp-not-inc',138714,'Some-college',10,'Married civ spouse','Sales','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (22,'Private',399087,'5th-6th',3,'Married civ spouse','Machine-op-inspct','Other-relative','White','Female',0,0,40,'Mexico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (29,'Private',423158,'Some-college',10,'Never married','Tech-support','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (62,'Private',159841,'HS-grad',9,'Widowed','Other-service','Not-in-family','White','Female',0,0,24,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (39,'Self-emp-not-inc',174308,'HS-grad',9,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Private',50356,'Some-college',10,'Married civ spouse','Craft-repair','Husband','White','Male',0,1485,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,'Private',186110,'HS-grad',9,'Divorced','Transport-moving','Not-in-family','White','Male',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (29,'Private',200381,'11th',7,'Never married','Exec managerial','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (76,'Self-emp-not-inc',174309,'Masters',14,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,10,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (63,'Self-emp-not-inc',78383,'HS-grad',9,'Married civ spouse','Farming-fishing','Husband','White','Male',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,NULL,211601,'Assoc-voc',11,'Never married',NULL,'Own-child','Black','Female',0,0,15,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Private',187728,'Some-college',10,'Married civ spouse','Prof-specialty','Wife','White','Female',0,1887,50,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (58,'Self-emp-not-inc',321171,'HS-grad',9,'Married civ spouse','Handlers-cleaners','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (66,'Private',127921,'HS-grad',9,'Never married','Transport-moving','Not-in-family','White','Male',2050,0,55,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Private',206565,'Some-college',10,'Never married','Craft-repair','Not-in-family','Black','Male',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (26,'Private',224563,'Bachelors',13,'Never married','Adm-clerical','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (47,'Private',178686,'Assoc-voc',11,'Never married','Other-service','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (55,'Local-gov',98545,'10th',6,'Married civ spouse','Adm-clerical','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (53,'Private',242606,'HS-grad',9,'Married civ spouse','Transport-moving','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (17,'Private',270942,'5th-6th',3,'Never married','Other-service','Other-relative','White','Male',0,0,48,'Mexico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',94235,'HS-grad',9,'Never married','Craft-repair','Other-relative','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (49,'Private',71195,'Masters',14,'Never married','Prof-specialty','Not-in-family','White','Male',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (19,'Private',104112,'HS-grad',9,'Never married','Sales','Unmarried','Black','Male',0,0,30,'Haiti',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (45,'Private',261192,'HS-grad',9,'Married civ spouse','Other-service','Husband','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (26,'Private',94936,'Assoc-acdm',12,'Never married','Sales','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Private',296478,'Assoc-voc',11,'Married civ spouse','Craft-repair','Husband','White','Male',7298,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (36,'State-gov',119272,'HS-grad',9,'Married civ spouse','Protective-serv','Husband','White','Male',7298,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',85043,'HS-grad',9,'Never married','Farming-fishing','Not-in-family','White','Male',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (22,'State-gov',293364,'Some-college',10,'Never married','Protective-serv','Own-child','Black','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Self-emp-not-inc',241895,'Bachelors',13,'Never married','Sales','Not-in-family','White','Male',0,0,42,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (67,NULL,36135,'11th',7,'Married civ spouse',NULL,'Husband','White','Male',0,0,8,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,NULL,151989,'Assoc-voc',11,'Divorced',NULL,'Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (56,'Private',101128,'Assoc-acdm',12,'Married-spouse-absent','Other-service','Not-in-family','White','Male',0,0,25,'Iran',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'Private',156464,'Bachelors',13,'Never married','Prof-specialty','Own-child','White','Male',0,0,25,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',117963,'Bachelors',13,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (26,'Private',192262,'HS-grad',9,'Married civ spouse','Other-service','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',111363,'Bachelors',13,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'Local-gov',329752,'11th',7,'Married civ spouse','Transport-moving','Husband','White','Male',0,0,30,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (59,NULL,372020,'Bachelors',13,'Married civ spouse',NULL,'Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Federal-gov',95432,'HS-grad',9,'Married civ spouse','Adm-clerical','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (65,'Private',161400,'11th',7,'Widowed','Other-service','Unmarried','Other','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'Private',96129,'Assoc-voc',11,'Married civ spouse','Tech-support','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (42,'Private',111949,'HS-grad',9,'Married civ spouse','Adm-clerical','Wife','White','Female',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (26,'Self-emp-not-inc',117125,'9th',5,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,40,'Portugal',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (36,'Private',348022,'10th',6,'Married civ spouse','Other-service','Wife','White','Female',0,0,24,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (62,'Private',270092,'Masters',14,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Private',180609,'Bachelors',13,'Married civ spouse','Transport-moving','Husband','White','Male',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Private',174575,'Bachelors',13,'Divorced','Exec managerial','Not-in-family','White','Male',0,1564,45,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (22,'Private',410439,'HS-grad',9,'Married-spouse-absent','Sales','Not-in-family','White','Male',0,0,55,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'Private',92262,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (56,'Self-emp-not-inc',183081,'Some-college',10,'Married civ spouse','Sales','Husband','White','Male',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (22,'Private',362589,'Assoc-acdm',12,'Never married','Sales','Not-in-family','White','Female',0,0,15,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (57,'Private',212448,'Bachelors',13,'Divorced','Exec managerial','Not-in-family','White','Female',0,0,45,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (39,'Private',481060,'HS-grad',9,'Divorced','Sales','Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (26,'Federal-gov',185885,'Some-college',10,'Never married','Adm-clerical','Unmarried','White','Female',0,0,15,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (17,'Private',89821,'11th',7,'Never married','Other-service','Own-child','White','Male',0,0,10,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'State-gov',184018,'Assoc-voc',11,'Married civ spouse','Machine-op-inspct','Husband','White','Male',0,0,38,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (45,'Private',256649,'HS-grad',9,'Married civ spouse','Machine-op-inspct','Husband','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Private',160323,'HS-grad',9,'Never married','Craft-repair','Not-in-family','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (20,'Local-gov',350845,'Some-college',10,'Never married','Adm-clerical','Own-child','White','Female',0,0,10,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',267404,'HS-grad',9,'Married civ spouse','Craft-repair','Wife','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,'Private',35633,'Some-college',10,'Never married','Sales','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'Self-emp-not-inc',80914,'Masters',14,'Divorced','Exec managerial','Not-in-family','White','Male',0,0,30,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Private',172927,'HS-grad',9,'Married civ spouse','Sales','Husband','White','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (54,'Private',174319,'HS-grad',9,'Divorced','Transport-moving','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'Private',214955,'5th-6th',3,'Divorced','Craft-repair','Not-in-family','White','Female',0,2339,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (25,'Private',344991,'Some-college',10,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'Private',108699,'Some-college',10,'Divorced','Sales','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (36,'Local-gov',117312,'Some-college',10,'Married civ spouse','Transport-moving','Wife','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,'Private',396099,'HS-grad',9,'Never married','Other-service','Not-in-family','White','Female',0,0,25,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (29,'Private',134152,'HS-grad',9,'Separated','Machine-op-inspct','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Private',162028,'Some-college',10,'Married civ spouse','Adm-clerical','Wife','White','Female',0,2415,6,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (19,'Private',25429,'Some-college',10,'Never married','Adm-clerical','Own-child','White','Female',0,0,16,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (19,'Private',232392,'HS-grad',9,'Never married','Other-service','Other-relative','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,'Private',220098,'HS-grad',9,'Married civ spouse','Other-service','Wife','White','Female',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (27,'Private',301302,'Bachelors',13,'Never married','Craft-repair','Not-in-family','White','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'Self-emp-not-inc',277946,'Assoc-acdm',12,'Separated','Craft-repair','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'State-gov',98101,'Bachelors',13,'Married civ spouse','Exec managerial','Husband','White','Male',7688,0,45,NULL,1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'Private',196164,'HS-grad',9,'Never married','Other-service','Not-in-family','White','Female',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Private',115562,'Some-college',10,'Married civ spouse','Tech-support','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (45,'Private',96975,'Some-college',10,'Divorced','Handlers-cleaners','Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (20,NULL,137300,'HS-grad',9,'Never married',NULL,'Other-relative','White','Female',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (25,'Private',86872,'Bachelors',13,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,55,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (52,'Self-emp-inc',132178,'Bachelors',13,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,50,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (20,'Private',416103,'Some-college',10,'Never married','Handlers-cleaners','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'Private',108574,'Some-college',10,'Never married','Other-service','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (50,'State-gov',288353,'Bachelors',13,'Married civ spouse','Protective-serv','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'Private',227689,'Assoc-voc',11,'Divorced','Tech-support','Not-in-family','White','Female',0,0,64,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'Private',166481,'7th-8th',4,'Married civ spouse','Handlers-cleaners','Husband','Other','Male',0,2179,40,'Puerto-Rico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Private',445382,'Masters',14,'Married civ spouse','Exec managerial','Husband','White','Male',0,1977,65,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'Private',110145,'HS-grad',9,'Married civ spouse','Adm-clerical','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'Self-emp-not-inc',317253,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,25,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,NULL,123147,'Some-college',10,'Married civ spouse',NULL,'Wife','White','Female',0,1887,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (32,'Private',364657,'Some-college',10,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Local-gov',42346,'Some-college',10,'Divorced','Other-service','Not-in-family','Black','Female',0,0,24,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (24,'Private',241951,'HS-grad',9,'Never married','Handlers-cleaners','Unmarried','Black','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',118500,'Some-college',10,'Divorced','Exec managerial','Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'Private',188386,'Doctorate',16,'Married civ spouse','Exec managerial','Husband','White','Male',15024,0,60,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (31,'State-gov',1033222,'Some-college',10,'Married civ spouse','Machine-op-inspct','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,'Private',92440,'12th',8,'Divorced','Craft-repair','Not-in-family','White','Male',0,0,50,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (52,'Private',190762,'1st-4th',2,'Married civ spouse','Machine-op-inspct','Husband','White','Male',0,0,40,'Mexico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',426017,'11th',7,'Never married','Other-service','Own-child','White','Female',0,0,19,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'Local-gov',243867,'11th',7,'Separated','Machine-op-inspct','Not-in-family','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'State-gov',240283,'HS-grad',9,'Divorced','Transport-moving','Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (20,'Private',61777,'Some-college',10,'Married civ spouse','Sales','Husband','White','Male',0,0,30,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (17,'Private',175024,'11th',7,'Never married','Handlers-cleaners','Own-child','White','Male',2176,0,18,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (32,'State-gov',92003,'Bachelors',13,'Married civ spouse','Exec managerial','Wife','White','Female',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (29,'Private',188401,'HS-grad',9,'Divorced','Farming-fishing','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',228528,'10th',6,'Never married','Craft-repair','Unmarried','White','Female',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (25,'Private',133373,'HS-grad',9,'Married civ spouse','Transport-moving','Husband','White','Male',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (36,'Federal-gov',255191,'Masters',14,'Never married','Prof-specialty','Not-in-family','White','Male',0,1408,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,'Private',204653,'HS-grad',9,'Never married','Handlers-cleaners','Not-in-family','White','Male',0,0,72,'Dominican-Republic',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (63,'Self-emp-inc',222289,'HS-grad',9,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (47,'Local-gov',287480,'Masters',14,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (80,NULL,107762,'HS-grad',9,'Widowed',NULL,'Not-in-family','White','Male',0,0,24,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (17,NULL,202521,'11th',7,'Never married',NULL,'Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'Self-emp-not-inc',204116,'Bachelors',13,'Married-spouse-absent','Prof-specialty','Not-in-family','White','Female',2174,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',29662,'Assoc-acdm',12,'Married civ spouse','Other-service','Wife','White','Female',0,0,25,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (27,'Private',116358,'Some-college',10,'Never married','Craft-repair','Own-child','Asian-Pac-Islander','Male',0,1980,40,'Philippines',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',208405,'Masters',14,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,50,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'Local-gov',284843,'HS-grad',9,'Never married','Farming-fishing','Not-in-family','Black','Male',594,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'Local-gov',117018,'Some-college',10,'Never married','Protective-serv','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,'Private',81281,'Some-college',10,'Married civ spouse','Adm-clerical','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (42,'Local-gov',340148,'Some-college',10,'Married civ spouse','Adm-clerical','Wife','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (29,'Private',363425,'Bachelors',13,'Never married','Prof-specialty','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (45,'Private',45857,'HS-grad',9,'Divorced','Adm-clerical','Not-in-family','White','Female',0,0,28,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (24,'Federal-gov',191073,'HS-grad',9,'Never married','Armed-Forces','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Private',116632,'Some-college',10,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (27,'Private',405855,'9th',5,'Never married','Craft-repair','Other-relative','White','Male',0,0,40,'Mexico',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (20,'Private',298227,'Some-college',10,'Never married','Sales','Not-in-family','White','Male',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Private',290521,'HS-grad',9,'Widowed','Exec managerial','Unmarried','Black','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (51,'Private',56915,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','Amer-Indian-Eskimo','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (20,'Private',146538,'HS-grad',9,'Married civ spouse','Machine-op-inspct','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (17,NULL,258872,'11th',7,'Never married',NULL,'Own-child','White','Female',0,0,5,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (19,'Private',206399,'HS-grad',9,'Never married','Machine-op-inspct','Own-child','Black','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (45,'Self-emp-inc',197332,'Some-college',10,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,55,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (60,'Private',245062,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (42,'Private',197583,'Assoc-acdm',12,'Married civ spouse','Exec managerial','Husband','Black','Male',0,0,40,NULL,1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Self-emp-not-inc',234885,'HS-grad',9,'Married civ spouse','Sales','Wife','White','Female',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'Private',72887,'Assoc-voc',11,'Married civ spouse','Machine-op-inspct','Husband','Asian-Pac-Islander','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',180374,'HS-grad',9,'Married civ spouse','Exec managerial','Wife','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Private',351299,'Some-college',10,'Married civ spouse','Transport-moving','Husband','Black','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,'Private',54012,'HS-grad',9,'Married civ spouse','Transport-moving','Husband','White','Male',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (32,NULL,115745,'Some-college',10,'Married civ spouse',NULL,'Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (44,'Private',116632,'Assoc-acdm',12,'Never married','Farming-fishing','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (54,'Local-gov',288825,'HS-grad',9,'Married civ spouse','Transport-moving','Husband','Black','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (32,'Private',132601,'Bachelors',13,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,50,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (50,'Private',193374,'1st-4th',2,'Married-spouse-absent','Craft-repair','Unmarried','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (24,'Private',170070,'Bachelors',13,'Never married','Tech-support','Not-in-family','White','Female',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (37,'Private',126708,'HS-grad',9,'Married civ spouse','Adm-clerical','Wife','White','Female',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (52,'Private',35598,'HS-grad',9,'Divorced','Transport-moving','Unmarried','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Private',33983,'Some-college',10,'Married civ spouse','Transport-moving','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (49,'Private',192776,'Masters',14,'Married civ spouse','Exec managerial','Husband','White','Male',0,1977,45,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',118551,'Bachelors',13,'Married civ spouse','Tech-support','Wife','White','Female',0,0,16,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (60,'Private',201965,'Some-college',10,'Never married','Prof-specialty','Unmarried','White','Male',0,0,40,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (22,NULL,139883,'Some-college',10,'Never married',NULL,'Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,'Private',285020,'HS-grad',9,'Never married','Craft-repair','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (30,'Private',303990,'HS-grad',9,'Never married','Transport-moving','Not-in-family','White','Male',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (67,'Private',49401,'Assoc-voc',11,'Divorced','Other-service','Not-in-family','White','Female',0,0,24,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'Private',279196,'Bachelors',13,'Never married','Craft-repair','Not-in-family','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (17,'Private',211870,'9th',5,'Never married','Other-service','Not-in-family','White','Male',0,0,6,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (22,'Private',281432,'Some-college',10,'Never married','Handlers-cleaners','Own-child','White','Male',0,0,30,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (27,'Private',161155,'10th',6,'Never married','Other-service','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,'Private',197904,'HS-grad',9,'Never married','Other-service','Unmarried','White','Female',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',111746,'Assoc-acdm',12,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,45,'Portugal',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (43,'Self-emp-not-inc',170721,'Some-college',10,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (28,'State-gov',70100,'Bachelors',13,'Never married','Prof-specialty','Not-in-family','White','Male',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Private',193626,'HS-grad',9,'Married-spouse-absent','Craft-repair','Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (52,NULL,271749,'12th',8,'Never married',NULL,'Other-relative','Black','Male',594,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (25,'Private',189775,'Some-college',10,'Married-spouse-absent','Adm-clerical','Own-child','Black','Female',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (63,NULL,401531,'1st-4th',2,'Married civ spouse',NULL,'Husband','White','Male',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (59,'Local-gov',286967,'HS-grad',9,'Married civ spouse','Transport-moving','Husband','White','Male',0,0,45,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (45,'Local-gov',164427,'Bachelors',13,'Divorced','Prof-specialty','Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (38,'Private',91039,'Bachelors',13,'Married civ spouse','Sales','Husband','White','Male',15024,0,60,'United States',1);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (40,'Private',347934,'HS-grad',9,'Never married','Other-service','Not-in-family','White','Female',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (46,'Federal-gov',371373,'HS-grad',9,'Divorced','Adm-clerical','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (35,'Private',32220,'Assoc-acdm',12,'Never married','Exec managerial','Not-in-family','White','Female',0,0,60,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (34,'Private',187251,'HS-grad',9,'Divorced','Prof-specialty','Unmarried','White','Female',0,0,25,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (33,'Private',178107,'Bachelors',13,'Never married','Craft-repair','Own-child','White','Male',0,0,20,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (41,'Private',343121,'HS-grad',9,'Divorced','Adm-clerical','Unmarried','White','Female',0,0,36,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (20,'Private',262749,'Some-college',10,'Never married','Machine-op-inspct','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (23,'Private',403107,'5th-6th',3,'Never married','Other-service','Own-child','White','Male',0,0,40,'El-Salvador',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (26,'Private',64293,'Some-college',10,'Never married','Prof-specialty','Not-in-family','White','Female',0,0,35,'United States',0);
	INSERT INTO "CHECK_APL"."SMALL_ADULT" VALUES (72,NULL,303588,'HS-grad',9,'Married civ spouse',NULL,'Husband','White','Male',0,0,20,'United States',1);

	SELECT COUNT(*) into NbSmallAdult FROM "CHECK_APL"."SMALL_ADULT";
	IF :NbSmallAdult <> 500
	THEN
		:results.insert(('Bad # of test records','ISSUE',:NbSmallAdult));
	ELSE
		:results.insert(('# of test records','OK',:NbSmallAdult));
	END IF;	

	:header.insert(('Oid', '#42'));
	:header.insert(('LogLevel', '8'));
	:header.insert(('ModelFormat', 'bin'));
	:config.insert(('APL/ModelType', 'binary classification',NULL));
--	:config.insert(('APL/MaxIterations', '100',NULL)); -- default value: 1000

	delete from :var_desc; -- to avoid a useless warning
	:var_role.insert(('class', 'target', NULL, NULL, NULL));
	-- Bug in SQLScript ?: the EXECUTE IMMEDIATE should be possible
    -- EXECUTE IMMEDIATE 'CALL "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role, ''CHECK_APL'', ''SMALL_ADULT'', model, out_log, out_sum, out_indic)' INTO model,out_log,out_sum,out_indic USING header,config,var_desc,var_role;
	CALL "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role, 'CHECK_APL', 'SMALL_ADULT', model, out_log, out_sum, out_indic);
	:results.insert(('Train in procedure mode','OK',NULL));
	:results.insert(('Checking train in procedure mode','Done',NULL));
	:results.insert(('____________________________',NULL,NULL));
END;



CREATE PROCEDURE "CHECK_APL"."SHAKE_APPLY_PROCEDURE_MODE"(IN model "CHECK_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID",OUT results "CHECK_APL"."CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE config "CHECK_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
	DECLARE header "CHECK_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
	DECLARE NbApplyOut INTEGER DEFAULT -1; 
	DECLARE NbApplyIn INTEGER DEFAULT 0; 
	DECLARE out_schema "CHECK_APL"."sap.pa.apl.base::BASE.T.TABLE_TYPE";
	DECLARE out_log "CHECK_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";
	DECLARE out_sum "CHECK_APL"."sap.pa.apl.base::BASE.T.SUMMARY";
	DECLARE out_apply_log "CHECK_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";
	DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:results.insert(('SHAKE_APPLY_PROCEDURE_MODE SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
	END;
	
	:results.insert(('Checking apply in procedure mode',NULL,NULL));
	:results.insert(('____________________________',NULL,NULL));

	delete from :config; -- suppress useless warning
	:header.insert(('Oid', '#42'));
	:header.insert(('LogLevel', '8'));
	:header.insert(('ModelFormat', 'bin'));
	-- Bug in SQLScript ?: the EXECUTE IMMEDIATE should be possible
	-- EXECUTE IMMEDIATE 'CALL "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header, :model, :config, ''CHECK_APL'',''SMALL_ADULT'',out_schema, out_log)' INTO out_schema,out_log USING header,model,config;
  	CALL "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header, :model, :config, 'CHECK_APL','SMALL_ADULT',out_schema, out_log);
    EXECUTE IMMEDIATE 'CALL "SAP_PA_APL"."sap.pa.apl.base::CREATE_TABLE_FROM_TABLE_TYPE"(''CHECK_APL'', ''SMALL_ADULT_APPLY_PROC'', :out_schema)' USING out_schema;
	-- Bug in SQLScript ?: the EXECUTE IMMEDIATE should be possible
    -- EXECUTE IMMEDIATE 'CALL "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL"(:header,  :model, :config, ''CHECK_APL'', ''SMALL_ADULT'', ''CHECK_APL'', ''SMALL_ADULT_APPLY_PROC'',out_apply_log, out_sum)' INTO out_apply_log, out_sum USING header,model,config ;
	CALL "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL"(:header,  :model, :config, 'CHECK_APL', 'SMALL_ADULT', 'CHECK_APL', 'SMALL_ADULT_APPLY_PROC',out_apply_log, out_sum);
	-- dynamic sql because SMALL_ADULT_APPLY_PROC does not exist yet
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "CHECK_APL"."SMALL_ADULT_APPLY_PROC"' INTO NbApplyOut; 	
	SELECT COUNT(*) into NbApplyIn FROM "CHECK_APL"."SMALL_ADULT";
    IF (:NbApplyOut<>500) OR (:NbApplyOut<>:NbApplyIn)
    THEN 
		:results.insert(('Bad # of output rows','ISSUE',:NbApplyOut));
    ELSE
		:results.insert(('# of output rows','OK',:NbApplyOut));
    END IF;
	:results.insert(('Checking apply in procedure mode','Done',NULL));
	:results.insert(('____________________________',NULL,NULL));
END;

-- Do the tests that need to be SYSTEM

-- connect SYSTEM PASSWORD &SYSTEM_PASSWORD;

-- Do the tests that need to be CHECK_APL

connect CHECK_APL PASSWORD &CHECK_APL_PASSWORD;

DO BEGIN
	DECLARE who_am_i NVARCHAR(100) DEFAULT '';
	DECLARE can_analyze BOOLEAN DEFAULT TRUE;
	DECLARE all_results "CHECK_APL"."CHECK_RESULTS_T";
	DECLARE final_results "CHECK_APL"."CHECK_RESULTS_T";
	DECLARE runtime_results "CHECK_APL"."CHECK_RESULTS_T";
	DECLARE ping_results "CHECK_APL"."CHECK_RESULTS_T";
	DECLARE train_procedure_results "CHECK_APL"."CHECK_RESULTS_T";
	DECLARE apply_procedure_results "CHECK_APL"."CHECK_RESULTS_T";
	DECLARE model "CHECK_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";	
	DECLARE nb_issues INTEGER DEFAULT 0;
	DECLARE ERROR_APL condition for SQL_ERROR_CODE 10001;
	DECLARE error_message NCLOB;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:final_results.insert(('RUN_TESTS_STEP2 SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
		SELECT * FROM :final_results;
		RESIGNAL;
	END;

	-- "CHECK_APL"."CHECK_APL_RESULTS" has been filled before as SYSTEM user
	all_results = SELECT * FROM "CHECK_APL"."APL_CHECK_RESULTS";
	IF "CHECK_APL"."HAS_SCRIPTSERVER"() = FALSE
	THEN
		IF "CHECK_APL"."HAS_APL"() = TRUE 
		THEN
			:final_results.insert(('===== APL is installed but cannot be run =====','ERROR','Script Server must be activated. See SAPNote 1650957'));
		ELSE
			:final_results.insert(('===== APL is not installed at ALL =====','ERROR',NULL));
		END IF;
		can_analyze = FALSE;
	ELSE
		IF "CHECK_APL"."HAS_APL"() = FALSE THEN
			:final_results.insert(('===== There is a script server but APL is not installed =====','ERROR',NULL));
			can_analyze = FALSE;
		END IF;
	END IF;

	if :can_analyze = TRUE
	THEN
		-- Ouf we can do some deeper checks 
		CALL "CHECK_APL"."SHAKE_APL_RUNTIME"(:runtime_results,:ping_results);
		:all_results.insert(:runtime_results);

		-- run pure functional tests
		EXECUTE IMMEDIATE 'CALL "CHECK_APL"."SHAKE_TRAIN_PROCEDURE_MODE"(:model,:train_procedure_results)' INTO model,train_procedure_results;
		:all_results.insert(:train_procedure_results);
		EXECUTE IMMEDIATE 'CALL "CHECK_APL"."SHAKE_APPLY_PROCEDURE_MODE"(:model,:apply_procedure_results)' INTO apply_procedure_results USING model;
		:all_results.insert(:apply_procedure_results);

		-- & Analysis all results to produce an abstract
		CALL "CHECK_APL"."ANALYZE_CHECKS"(:all_results,:final_results);

		-- complete abstract with all ping informations
		:final_results.insert(('','',NULL));
		:final_results.insert(('===== APL informations =====',NULL,NULL));
		:final_results.insert(('============================',NULL,NULL));
		:final_results.insert(:ping_results);
		:final_results.insert(('============================',NULL,NULL));
		:final_results.insert(('===== APL informations =====',NULL,NULL));
		:final_results.insert(('____________________________',NULL,NULL));
		:final_results.insert(('','',NULL));
		
		-- append all logs
		:final_results.insert(('Here are the full logs of analysis',NULL,NULL));
		:final_results.insert(('____________________________',NULL,NULL));
		:final_results.insert(:all_results);
	ELSE
	END IF;
	SELECT * FROM :final_results;
	-- keep using LOWER. This is not a mistake
	SELECT LOWER(SESSION_USER) into who_am_i FROM "DUMMY";
	IF :who_am_i <> 'check_apl' 
	THEN
		-- do the final check and pop an sql error
		-- if an issue is detected
		SELECT COUNT(*) into nb_issues FROM :final_results WHERE "STATUS" IN ('ISSUE','ERROR');
		IF :nb_issues > 0
		THEN
			SELECT '['||STRING_AGG("KEY" || ' ' || COALESCE("STATUS",'') || ' ' || COALESCE("DETAILS",'') || CHAR(10))||']' INTO error_message FROM :final_results;		
			SIGNAL ERROR_APL set MESSAGE_TEXT = :error_message;
		END IF;
	END IF;
END;

-- Clean everything (need to be system)

connect SYSTEM PASSWORD &SYSTEM_PASSWORD;
DROP USER CHECK_APL CASCADE;

