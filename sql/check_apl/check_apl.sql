-- ================================================================
-- @required(hanaMinimumVersion,2.0.30)
-- This script is compatible with HANA 2 and Hana Cloud
-- The purpose of this script is to validate the APL installation by:
-- checking APL is properly installed:
--      APL low level functions are installed
--      APL high level functions are installed
--      APL rights are available and can be granted
--  checking APL run time is OK:
--      check APL ping can be called
--      check results of APL ping
-- 
-- 
-- Assumption: The scripserver is already enabled 
--
-- Output: a result set with 3 parts
--  High level status (OK,ERROR) for install checks as well as run time checks 
--  Detailed infos on each check. Status can be OK or ISSUE
--  A copy of the APL ping results which provide detailed version informations

-- Command line to run this script is:
-- hdbsql -n <HostName>:<port> -u SYSTEM -p <System password> -I .check_apl.sql -g '' -V SYSTEM_PASSWORD=<System password> -j -A 2>/dev/null >./check_results.txt
-- Ex: hdbsql -n localhost:30041 -u SYSTEM -p Password1 -I ./check_apl.sql -g '' -V SYSTEM_PASSWORD=Password1 -j -A 2>/dev/null >./check_results.txt

-- More details are available in readme.md

connect SYSTEM PASSWORD &SYSTEM_PASSWORD;

DROP USER CHECK_APL CASCADE;
CREATE USER CHECK_APL PASSWORD Password1;
ALTER USER CHECK_APL DISABLE PASSWORD lifetime;

connect CHECK_APL PASSWORD Password1;
GRANT ALL PRIVILEGES ON SCHEMA "CHECK_APL" TO SYSTEM;

connect SYSTEM PASSWORD &SYSTEM_PASSWORD;
CREATE TYPE "CHECK_APL"."CHECK_APL_RESULTS_T" AS TABLE ("KEY" NVARCHAR(255),"STATUS" NVARCHAR(256),"DETAILS" NVARCHAR(1000));
-- recreate this type so we don't depend on a successfull deployment of APL types
CREATE TYPE "CHECK_APL"."PING_OUTPUT_T" AS TABLE ("name" VARCHAR(128),"value" VARCHAR(1024));

-- this table will be needed in HANA 1.2
CREATE TABLE "CHECK_APL"."COUNT_ACTIVE_OBJECTS" (NB_ACTIVE_OBJECTS INTEGER);


CREATE FUNCTION "CHECK_APL"."IS_HCE"()
RETURNS is_hce BOOLEAN
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
DETERMINISTIC 
AS BEGIN
	DECLARE major INT;
	SELECT cast(substr_before (version, '.') as int) INTO major FROM M_DATABASE;
	 IF :major >=4
	 THEN
	 	is_hce = true;
	 ELSE
	 	is_hce = false;
	 END IF;
END;


CREATE PROCEDURE "CHECK_APL"."CHECK_APL_INSTALL"(OUT results "CHECK_APL"."CHECK_APL_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE STATUS_1 NVARCHAR(1000);
	DECLARE STATUS_2 NVARCHAR(1000);
	DECLARE TEXT_1 NVARCHAR(1000);
	DECLARE NB INTEGER;
	DECLARE FINAL_STATUS NVARCHAR(100) = 'OK';
	DECLARE IS_HCE BOOLEAN = "CHECK_APL"."IS_HCE"();
	DECLARE INVALID_RESULT condition for SQL_ERROR_CODE 10001;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:results.insert(('CHECK_APL_INSTALL SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
		COMMIT WORK;
	END;
	:results.insert(('Checking installation of APL plugin',NULL,NULL));
	:results.insert(('============================',NULL,NULL));
	SELECT ERROR_TEXT into text_1 FROM m_plugin_status WHERE PLUGIN_NAME='sap_afl_sdk_apl';
	SELECT AREA_STATUS into status_1 FROM m_plugin_status WHERE PLUGIN_NAME='sap_afl_sdk_apl';
	SELECT PACKAGE_STATUS into status_2 FROM m_plugin_status WHERE PLUGIN_NAME='sap_afl_sdk_apl';
	IF :status_1<>'REGISTRATION SUCCESSFUL' OR :status_2<>'REGISTRATION SUCCESSFUL'
	THEN
		:results.insert(('Bad high level status of APL AFL plugin','ISSUE',:status_1 || '/' || :status_2));
		:results.insert(('AFL diagnostic','ISSUE',:text_1));
		final_status = 'ISSUE';
	ELSE
		:results.insert(('Good high level status of APL AFL install','OK',:status_1));	
	END IF;
	:results.insert(('Checking registration of low level APL API',NULL,NULL));
	:results.insert(('============================',NULL,NULL));
	SELECT COUNT(*) into nb FROM "SYS"."AFL_AREAS" WHERE AREA_NAME='APL_AREA';
	IF :nb <> 1 
	THEN
		:results.insert(('Bad # of APL AREA','ISSUE',:nb));
		final_status = 'ISSUE';
	ELSE
		:results.insert(('Good # of APL AREA','OK',:nb));
	END IF;
	SELECT COUNT(*) into nb FROM "SYS"."AFL_PACKAGES" WHERE AREA_NAME='APL_AREA';
	IF :nb <> 1 
	THEN
		:results.insert(('Bad # of APL PACKAGES','ISSUE',:nb));
		final_status = 'ISSUE';
	ELSE
		:results.insert(('Good # of APL PACKAGES','OK',:nb));
	END IF;
	SELECT COUNT(*) into nb FROM  "SYS"."AFL_FUNCTIONS_" F,
	    "SYS"."AFL_AREAS" A
	WHERE "A"."AREA_NAME"='APL_AREA'
	AND "A"."AREA_OID" = "F"."AREA_OID";
	-- 54 for master
	-- 52 for cor/pa 3.3
	IF :nb <52 
	THEN
		:results.insert(('Bad # of APL low level calls','ISSUE',:nb));
		final_status = 'ISSUE';
	ELSE
		:results.insert(('Good # of APL low level calls','OK',:nb));
	END IF;
	SELECT COUNT(*) into nb FROM "SYS"."AFL_FUNCTION_PARAMETERS" WHERE AREA_NAME='APL_AREA';
	-- 821 for master
	-- 796 for cor/pa3.3
	IF :nb <796
	THEN
		:results.insert(('Bad # of descriptions of APL low level calls','ISSUE',:nb));
		final_status = 'ISSUE';
	ELSE
		:results.insert(('Good # of descriptions of APL low level calls','OK',:nb));
	END IF;

	:results.insert(('Checking registration of high level APL API (APL DU or Hana Cloud SQLAutoContent)',null,null));
	:results.insert(('============================',null,null));	
	SELECT COUNT(*) into nb FROM Roles WHERE ROLE_NAME like '%APL%_EXECUTE%';
	IF :nb <>3 
	THEN
		:results.insert(('Bad # of APL roles','ISSUE',:nb));
		final_status = 'ISSUE';
	ELSE
		:results.insert(('Good # of APL roles','OK',:nb));
	END IF;
	SELECT COUNT(*) into nb FROM Roles WHERE ROLE_NAME='sap.pa.apl.base.roles::APL_EXECUTE';
	IF :nb <>1 
	THEN
		:results.insert(('Missing main APL role sap.pa.apl.base.roles::APL_EXECUTE','ISSUE',:nb));
		final_status = 'ISSUE';
	ELSE
		:results.insert(('Main APL role sap.pa.apl.base.roles::APL_EXECUTE is declared','OK',:nb));
	END IF;
	SELECT COUNT(*) into nb FROM M_TABLES WHERE SCHEMA_NAME = 'SAP_PA_APL';
	IF :nb < 31
	THEN
		:results.insert(('Bad # of APL artefacts','ISSUE',:nb));
		final_status = 'ISSUE';
	ELSE
		:results.insert(('Good # of APL artefacts','OK',:nb));
	END IF;
	SELECT COUNT(*) into nb FROM "PUBLIC"."PROCEDURES" WHERE SCHEMA_NAME LIKE 'SAP_PA_APL';
	IF :nb <73
	THEN
		:results.insert(('Bad # of high level APL APIs','ISSUE',:nb));
		final_status = 'ISSUE';
	ELSE
		:results.insert(('Good # of high level APL APIs','OK',:nb));
	END IF;
	IF :IS_HCE = true
	THEN
		EXEC 'GRANT "sap.pa.apl.base.roles::APL_EXECUTE" TO CHECK_APL';
		:results.insert(('grant successful "sap.pa.apl.base.roles::APL_EXECUTE" to CHECK_APL','OK',NULL));
	ELSE
		-- Need to use an exec so it can be compiled even on hana cloud
		-- cannot use new advanced SQLScript features so it can run on HANA 1.2 and HANA 2.0
		EXEC 'INSERT INTO "CHECK_APL"."COUNT_ACTIVE_OBJECTS" SELECT COUNT(*) FROM "_SYS_REPO"."ACTIVE_OBJECT" AS T1 LEFT OUTER JOIN "_SYS_REPO"."PACKAGE_CATALOG" AS T2 ON T1."PACKAGE_ID" = T2."PACKAGE_ID" WHERE T2."DELIVERY_UNIT"=''HCO_PA_APL'' AND T1."OBJECT_STATUS"= 0';
		SELECT NB_ACTIVE_OBJECTS into nb FROM "CHECK_APL"."COUNT_ACTIVE_OBJECTS";	
		IF :nb < 77
		THEN
			:results.insert(('Bad # of activated high level APL APIs: APL DU is not activated','ISSUE',:nb));
			final_status = 'ISSUE';
		ELSE
			:results.insert(('Good # of activated high level APL APIs: APL DU is activated','OK',:nb));
		END IF;
		EXEC 'call _SYS_REPO.GRANT_ACTIVATED_ROLE (''sap.pa.apl.base.roles::APL_EXECUTE'',''CHECK_APL'')';
		:results.insert(('GRANT_ACTIVATED_ROLE successful "sap.pa.apl.base.roles::APL_EXECUTE" to CHECK_APL','OK',NULL));
	END IF;
	IF :final_status = 'ISSUE'
	THEN
		:results.insert(('Check APL plugin done','ERROR',NULL));
	ELSE
		:results.insert(('Check APL plugin done','OK',NULL));
	END IF;
	:results.insert(('============================',NULL,NULL));
END;

CREATE PROCEDURE "CHECK_APL"."CHECK_APL_RUNTIME"(OUT results "CHECK_APL"."CHECK_APL_RESULTS_T", OUT ping_proc "CHECK_APL"."PING_OUTPUT_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE NB INTEGER;
	DECLARE NB_MIN INTEGER;
	DECLARE FINAL_STATUS NVARCHAR(100) = 'OK';
	DECLARE IS_HCE BOOLEAN = "CHECK_APL"."IS_HCE"();
	DECLARE ping_direct "CHECK_APL"."PING_OUTPUT_T";
	DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:results.insert(('CHECK_APL_RUNTIME SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
		COMMIT WORK;
	END;
	:results.insert(('Checking APL run time',NULL,NULL));
	:results.insert(('============================',NULL,NULL));

	:results.insert(('Checking PING (proc mode)',NULL,NULL));
	-- use an exec so this code can be compiled by SYSTEM
	EXEC 'CALL "SAP_PA_APL"."sap.pa.apl.base::PING"(:ping_proc)' into ping_proc;
	:results.insert(('Calling proc PING successful','OK',NULL));
	:results.insert(('Analyzing results of PING',NULL,NULL));
	SELECT COUNT(*) into nb FROM :ping_proc;
	if :IS_HCE=TRUE
	THEN
		NB_MIN = 21; 
	ELSE
		NB_MIN = 17;
	END IF;
	IF :nb < :NB_MIN
	THEN
		:results.insert(('Issue: proc ping results should be at least ' || :NB_MIN || ' rows and are actually','ISSUE',:nb));
		final_status = 'ISSUE';
	ELSE
		:results.insert(('proc PING results looks like OK','OK',:nb));	
	END IF;
	IF :IS_HCE=true 
	THEN
		SELECT COUNT(*) into nb FROM :ping_proc WHERE "name" LIKE 'SQLAutoContent%';
		if :nb <>3
		THEN
			:results.insert(('Issue: HCE marker tags in proc PING results should be 3 and are actually','ISSUE',:nb));
			final_status = 'ISSUE';
		ELSE
			:results.insert(('Found HCE tags in proc PING results','OK',:nb));		
		END IF;
	END IF;
	:results.insert(('============================',NULL,NULL));

	:results.insert(('Checking PING (direct mode)',NULL,NULL));
	-- use an exec so this code can be compiled  by SYSTEM
	EXEC 'CALL _SYS_AFL.APL_AREA_PING_PROC(:ping_direct)' into ping_direct;
	:results.insert(('Calling direct PING successful','OK',NULL));
	:results.insert(('Analyzing results of PING',NULL,NULL));
	SELECT COUNT(*) into nb FROM :ping_direct;
	IF :nb < 17
	THEN
		:results.insert(('Issue: direct ping results should be at least 17 rows and are actually','ISSUE',:nb));
		final_status = 'ISSUE';
	ELSE
		:results.insert(('direct PING results looks like OK','OK',:nb));	
	END IF;
	IF :final_status='ISSUE'
	THEN
		:results.insert(('Check APL runtime done','ERROR',NULL));
	ELSE
		:results.insert(('Check APL runtime done','OK',NULL));
	END IF;
	:results.insert(('============================',NULL,NULL));
END;

CREATE PROCEDURE "CHECK_APL"."ANALYZE_CHECKS"(
	IN check_results "CHECK_APL"."CHECK_APL_RESULTS_T",
	OUT FinalResults "CHECK_APL"."CHECK_APL_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE nb_issues INTEGER = 0;
	DECLARE nb_fatal_errors INTEGER = 0;
	DECLARE check_install_ended INTEGER = 0;
	DECLARE check_runtime_ended INTEGER = 0;
	DECLARE error_message NVARCHAR(5000) = null;
	DECLARE apl_ok NVARCHAR(5000) = 'OK';
	DECLARE issues "CHECK_APL"."CHECK_APL_RESULTS_T";

	SELECT COUNT(*) into nb_issues FROM :check_results WHERE Status='ISSUE';
	SELECT COUNT(*) into check_install_ended FROM :check_results WHERE KEY ='Check APL plugin done';
	SELECT COUNT(*) into check_runtime_ended FROM :check_results WHERE KEY = 'Check APL runtime done';
	
	if check_install_ended=1
	then
		 :FinalResults.insert(('Analysis of install of APL plugin properly ended','OK',null));
	else
		SELECT Details into error_message FROM :check_results WHERE KEY='CHECK_APL_INSTALL SQLScript error:' LIMIT 1 ;
		:FinalResults.insert(('Analysis of install of APL plugin unexpectedly ended','ERROR','Reported failure is ' || :error_message)  );
		apl_ok = 'ERROR';
	end if; 
	if check_runtime_ended=1
	then
		:FinalResults.insert(('Analysis of APL runtime properly ended','OK',null));
	else
		SELECT details into error_message FROM :check_results WHERE KEY='CHECK_APL_RUNTIME SQLScript error:' LIMIT 1;
		:FinalResults.insert(('Analysis of APL runtime unexpectedly ended','ERROR','Reported failure is ' || :error_message)  );
		apl_ok = 'ERROR';
	end if;
	if :apl_ok <>'OK'
	then
		:FinalResults.insert(('All tests were not done. List of issues is therefore not complete',null,null));
	else
		:FinalResults.insert(('All tests were done. List of issues is supposed to be complete',null,null));
	end if;
	if :nb_issues > 0
	then
		:FinalResults.insert(('There are ' || :nb_issues ||' detected issues in APL install or runtime','ERROR','Please provide this log to support'));
		issues = SELECT * FROM :check_results WHERE Status='ISSUE';
		:FinalResults.insert(:issues);
		apl_ok = 'ERROR';
	else
		:FinalResults.insert(('No issue detected in APL install/runtime','OK',null));
	end if;
	:FinalResults.insert(('============================',null,null));
	:FinalResults.insert(('Here are the full logs of analysis',null,null));
	:FinalResults.insert(('============================',null,null));
	:FinalResults.insert(:check_results);
END;

CREATE TABLE "CHECK_APL"."APL_CHECK_RESULTS" LIKE "CHECK_APL"."CHECK_APL_RESULTS_T";
DO BEGIN
	CALL "CHECK_APL"."CHECK_APL_INSTALL"(:install_results);
    INSERT INTO "CHECK_APL"."APL_CHECK_RESULTS" SELECT * FROM :install_results;
END;


connect CHECK_APL PASSWORD Password1;
DO BEGIN
	CALL "CHECK_APL"."CHECK_APL_RUNTIME"(:runtime_results,:ping_results);
    INSERT INTO "CHECK_APL"."APL_CHECK_RESULTS" SELECT * FROM :runtime_results;
	check_results = SELECT * FROM "CHECK_APL"."APL_CHECK_RESULTS";
	CALL "CHECK_APL"."ANALYZE_CHECKS"(:check_results,:final_results);
    TRUNCATE TABLE "CHECK_APL"."APL_CHECK_RESULTS";
    INSERT INTO "CHECK_APL"."APL_CHECK_RESULTS" SELECT * FROM :final_results;
    INSERT INTO "CHECK_APL"."APL_CHECK_RESULTS" VALUES ('===== APL informations =====',NULL,NULL);
    INSERT INTO "CHECK_APL"."APL_CHECK_RESULTS" VALUES ('============================',NULL,NULL);
	INSERT INTO "CHECK_APL"."APL_CHECK_RESULTS" (SELECT "name" || ': ' || "value" as "KEY",NULL AS "STATUS",NULL AS "DETAILS" FROM :ping_results);
    INSERT INTO "CHECK_APL"."APL_CHECK_RESULTS" VALUES ('============================',NULL,NULL);
    INSERT INTO "CHECK_APL"."APL_CHECK_RESULTS" VALUES ('===== APL informations =====',NULL,NULL);
	SELECT * FROM "CHECK_APL"."APL_CHECK_RESULTS";
END;


connect SYSTEM PASSWORD &SYSTEM_PASSWORD;
DROP USER CHECK_APL CASCADE;

