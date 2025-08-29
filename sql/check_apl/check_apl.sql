-- ================================================================
-- This SQL script is compatible with HANA 2 and Hana Cloud
-- The purpose of this script is to analysis various aspects of the APL installation:
--	 APL plugin
--	 APL Delivery Unit
--	 APL role and rights
--	 Some known deployment issues 
--	 APL runtime
--	 Informations about the OS and HANA instance
--	 some standard support statements suitable for the current HANA instance

-- It is meant to be run by a user with high privileges (SYSTEM or DBADMIN) and will create a user CHECK_APL to actually run the checks.
-- This user will be dropped at the end of the script.

-- This SQL script can be run only by standard SAP hdbsql command line tool available in every HANA installation

-- The Unix script check_apl is provided to run this SQL script with the right parameters
-- The script will generate a markdown output that document the APL installation and runtime
-- The output is meant to be used as a markdown file, so it can be easily read in a browser or in any markdown viewer

-- Usage:
--   check_apl [OPTIONS]
--
-- Options:
--  -h, --host <host:port>              HANA DB host and port (default: hana:30015)
--  -u, --user <user>                   HANA DB user (default: SYSTEM)
--  -p, --password <password>           HANA DB user password (default: Manager1)
--  -f, --format <format>               Output format: md (Markdown), raw. (default: md)
--  -s, --signal-error <on|off>         Signal error in output (default: off)
--  --check_apl-password <password>     Password for CHECK_APL user (default: Password1)
--  --help                              Show this help message and exit
--
-- Example:
--   ./check_apl -h hana:30015 -u SYSTEM -p MySystemPassword 
--
-- Advanced and optional parameters:
-- -s, --signal-error: If set to 'off' (default value), the script will generate a report. If set to 'on' the script will signal an error in the output if any issue is found during the checks, 
-- -f, --format: The output format can be 'md' (Markdown) or 'raw' (raw SQL output). The default is 'md'.
-- --check_apl-password: The password for the CHECK_APL user. The default password for user CHECK_APL may be rejected by current password policy of HANA. in such a case, you can set this parameter to a valid password for CHECK_APL user.

-- Note
-- * On recent HANA Cloud versions, a DBADMIN user is available and should be used instead of SYSTEM to run this script

-- More details are available in readme.md


-- use hdbsql's macros to provide user with high privileges and its password
connect &SYSTEM_USER PASSWORD &SYSTEM_PASSWORD;


DROP USER CHECK_APL CASCADE;
CREATE USER CHECK_APL PASSWORD &CHECK_APL_PASSWORD;
ALTER USER CHECK_APL DISABLE PASSWORD lifetime;

DO BEGIN
	DECLARE major INT;
	DECLARE nb_import_threads INT;
	DECLARE note_results TABLE ("Note|Status" NVARCHAR(5000));
	:note_results.insert(('# Check APL installation and runtime ' || current_date || ' ' || current_time));
	:note_results.insert(('## Notes'));
	:note_results.insert(('Note|Status'));
	:note_results.insert((REPLACE('___|___','_','-')));
	
	SELECT CAST(SUBSTR_BEFORE ("VERSION", '.') AS INT) into major FROM "M_DATABASE";
	IF :major < 4
	THEN
		-- this has a meaning only on HANA On Premise
		EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM "M_SERVICE_THREADS" WHERE UPPER("THREAD_TYPE") LIKE ''IMPORT%''' INTO nb_import_threads;
		IF :nb_import_threads > 0
		THEN
			:note_results.insert(('Some import process is still running and may impact results of this check. We advise to rerun after end of all imports|WARNING'));
		END IF;

		EXECUTE IMMEDIATE 'GRANT SELECT ON "_SYS_REPO"."DELIVERY_UNITS" TO CHECK_APL';
		EXECUTE IMMEDIATE 'GRANT SELECT ON "_SYS_REPO"."ACTIVE_OBJECT" TO CHECK_APL';
		:note_results.insert(('Some specific read-only rights have been granted to user CHECK_APL so APL''s Delivery Unit checks can be done|Information'));
	END IF;	
	EXECUTE IMMEDIATE 'GRANT SERVICE ADMIN TO CHECK_APL';
	EXECUTE IMMEDIATE 'GRANT MONITORING  TO CHECK_APL';
	:note_results.insert(('SERVICE ADMIN and MONITORING rights have been granted to user CHECK_APL so scriptserver and system informations can be checked|Information'));
	SELECT * FROM :note_results;
	SELECT '' FROM DUMMY;
END;




-- prerequisites: standard APL rights
-- we try to resist to not having APL installed
-- if missing, this should just log an error message
-- analysis is done later
GRANT AFLPM_CREATOR_ERASER_EXECUTE TO CHECK_APL;
GRANT AFL__SYS_AFL_APL_AREA_EXECUTE TO CHECK_APL;

DO BEGIN
	DECLARE major INT;
    DECLARE prerequisite_results TABLE ("COL1" NVARCHAR(255),"COL2" NVARCHAR(255),"COL3" NVARCHAR(255));

	IF NOT EXISTS(SELECT * FROM "SYS"."ROLES" WHERE "ROLE_NAME"='AFL__SYS_AFL_APL_AREA_EXECUTE')
	THEN
		:prerequisite_results.insert(('Granting basic APL right','Missing role AFL__SYS_AFL_APL_AREA_EXECUTE TO CHECK_APL', 'APL plugin is probably not installed'));
	END IF;
	SELECT CAST(SUBSTR_BEFORE ("VERSION", '.') AS INT) into major FROM "M_DATABASE";
	IF :major < 4
	THEN
	 	-- this has a meaning only on HANA On Premise
	       IF EXISTS(SELECT * FROM "SYS"."ROLES" WHERE "ROLE_NAME"='sap.pa.apl.base.roles::APL_EXECUTE')
	       THEN
			   EXECUTE IMMEDIATE 'CALL "_SYS_REPO"."GRANT_ACTIVATED_ROLE" (''sap.pa.apl.base.roles::APL_EXECUTE'',''CHECK_APL'')';
			ELSE
				:prerequisite_results.insert(('Granting APL DU right','Missing role sap.pa.apl.base.roles::APL_EXECUTE','APL DU is probably not installed'));
			END IF;
	ELSE
	 	-- this has a meaning only on HANA Cloud
		   EXECUTE IMMEDIATE 'GRANT "sap.pa.apl.base.roles::APL_EXECUTE" TO CHECK_APL';
	 END IF;
	 IF NOT IS_EMPTY(:prerequisite_results)
	 THEN
	 	SELECT '## Prerequisites' FROM DUMMY;
		SELECT '|FATAL ERROR|Details|DIAGNOSTIC|' FROM DUMMY;	 
		SELECT REPLACE('|___|___|___|','_','-') FROM DUMMY;	 
		:prerequisite_results.insert(('Prerequisite not reached: APL is probably not installed','','Install APL'));
		SELECT '|' || COALESCE("COL1",'') || '|' || COALESCE("COL2",'') || '|' || COALESCE("COL3",'') || '|' FROM :prerequisite_results;	
		SELECT '' FROM DUMMY;
	 END IF;
END;

-- now we can run analysis

-- use a hdbsql's macro to use the password of CHECK_APL
connect CHECK_APL PASSWORD &CHECK_APL_PASSWORD;

-- Here are the exact raw sequence to properly create a check user that will be able to do all the deep checks
-- DROP USER CHECK_APL CASCADE;
-- CREATE USER CHECK_APL PASSWORD Password1;;
-- ALTER USER CHECK_APL DISABLE PASSWORD lifetime;
-- GRANT AFLPM_CREATOR_ERASER_EXECUTE TO CHECK_APL;
-- GRANT AFL__SYS_AFL_APL_AREA_EXECUTE TO CHECK_APL;
-- OnPremise: CALL "_SYS_REPO"."GRANT_ACTIVATED_ROLE" ('sap.pa.apl.base.roles::APL_EXECUTE','CHECK_APL');
-- HCE: GRANT "sap.pa.apl.base.roles::APL_EXECUTE" TO CHECK_APL;
-- GRANT SERVICE ADMIN TO CHECK_APL;
-- GRANT MONITORING  TO CHECK_APL;
-- GRANT SELECT ON "_SYS_REPO"."DELIVERY_UNITS" TO CHECK_APL;
-- GRANT SELECT ON "_SYS_REPO"."ACTIVE_OBJECT" TO CHECK_APL;

-- If you have created your own user for check, you can execute all code after that
-- except the final DROP USER CHECK_APL CASCADE

----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------

-- recreate these types so we don't depend on a successfull deployment of APL types

CREATE TYPE "CHECK_RESULTS_T" AS TABLE ("KEY" NVARCHAR(256),"STATUS" NVARCHAR(256),"DETAILS" NVARCHAR(5000));

CREATE TYPE "MD_OUTPUT_T" AS TABLE ("MD_LINE" NVARCHAR(5000));

CREATE FUNCTION "FILTER_SPECIAL_MD_CHARS"( IN input NVARCHAR(5000))
RETURNS filtered NVARCHAR(5000)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
DETERMINISTIC 
AS BEGIN
	filtered := REPLACE(REPLACE(COALESCE(:input,''),'<','&lt;'),'>','&gt;');
END;


CREATE PROCEDURE "OUTPUT_AS_MD_3_FIELDS"(
	IN res CHECK_RESULTS_T,
	OUT md_output MD_OUTPUT_T
	)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
AS BEGIN
	DECLARE TOC MD_OUTPUT_T;
	DECLARE Content_md MD_OUTPUT_T;
	DECLARE CURSOR cur FOR SELECT "KEY", "STATUS", "DETAILS" FROM :res WHERE "KEY" NOT LIKE '!_!_%' ESCAPE '!';

	FOR cur_row AS cur DO
		IF cur_row.KEY = 'status:'
		THEN
			continue;
		END IF;
		IF cur_row.KEY = 'title:'
		THEN
			:Content_md.insert(('## ' ||:cur_row.DETAILS));
			:TOC.insert(('- ['||:cur_row.DETAILS||'](#'||LOWER(REPLACE(:cur_row.DETAILS,' ','-'))||')'));
			continue;
		END IF;
		IF cur_row.KEY = 'table:'
		THEN
			IF cur_row.STATUS = ''
			THEN
				-- no specific header, we use the default one
				:Content_md.insert(('| | | |'));
			ELSE
				-- status contains specific header
				:Content_md.insert((cur_row.STATUS));
			END IF;
			:Content_md.insert((REPLACE('|___|___|___|','_','-')));
			continue;
		END IF;
		IF cur_row.KEY = 'section:'
		THEN
			:Content_md.insert(('### ' ||:cur_row.DETAILS));
			:TOC.insert(('    - ['||:cur_row.DETAILS||'](#'||LOWER(REPLACE(:cur_row.DETAILS,' ','-'))||')'));
			continue;
		END IF;
		IF cur_row.KEY = 'subsection:'
		THEN
			:Content_md.insert(('#### ' ||:cur_row.DETAILS));
			:TOC.insert(('        - ['||:cur_row.DETAILS||'](#'||LOWER(REPLACE(:cur_row.DETAILS,' ','-'))||')'));
			-- subsection is always followed by a table
			IF cur_row.STATUS = ''
			THEN
				-- no specific header, we use the default one
				:Content_md.insert(('| | | |'));
			ELSE
				-- status contains specific header
				:Content_md.insert((cur_row.STATUS));
			END IF;
			:Content_md.insert((REPLACE('|___|___|___|','_','-')));
			continue;
		ELSE
			:Content_md.insert(('|' || "FILTER_SPECIAL_MD_CHARS"(cur_row.KEY) || '|' ||"FILTER_SPECIAL_MD_CHARS"(cur_row.STATUS) || '|' || "FILTER_SPECIAL_MD_CHARS"(cur_row.DETAILS) || '|'));
		END IF;
	END FOR;
	:md_output.insert(:TOC);
	:md_output.insert(:Content_md);
END;

CREATE TYPE "PING_OUTPUT_T" AS TABLE (
	"name" VARCHAR(128),
	"value" VARCHAR(1024));


CREATE TYPE "sap.pa.apl.base::BASE.T.MODEL_BIN_OID" AS TABLE (
    "OID" VARCHAR(50),
    "FORMAT" VARCHAR(50),
    "LOB" CLOB
);

CREATE TYPE "sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED" AS TABLE(
	"KEY" VARCHAR(1000),
    "VALUE" CLOB,
    "CONTEXT" VARCHAR(100)

);

CREATE TYPE "sap.pa.apl.base::BASE.T.FUNCTION_HEADER" AS TABLE(
	"KEY" VARCHAR(50),
    "VALUE" VARCHAR(255)
);

CREATE TYPE "sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID" AS TABLE(
	"NAME" VARCHAR(255),
    "ROLE" VARCHAR(10),
    "COMPOSITION_TYPE" VARCHAR(10),
    "COMPONENT_NAME" VARCHAR(255),
    "OID" VARCHAR(50)
);

CREATE TYPE "sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID" AS TABLE(
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

CREATE TYPE "sap.pa.apl.base::BASE.T.TABLE_TYPE" as table (
    "OID" VARCHAR(50),
    "POSITION" INTEGER, 
    "NAME" VARCHAR(255), 
    "KIND" VARCHAR(50), 
    "PRECISION" INTEGER, 
    "SCALE" INTEGER, 
    "MAXIMUM_LENGTH" INTEGER
);

CREATE TYPE "sap.pa.apl.base::BASE.T.OPERATION_LOG" AS TABLE (
    "OID" VARCHAR(50),
    "TIMESTAMP" TIMESTAMP,
    "LEVEL" INTEGER,
    "ORIGIN" VARCHAR(50),
    "MESSAGE" NCLOB
);

CREATE TYPE "sap.pa.apl.base::BASE.T.SUMMARY" AS TABLE (
    "OID" VARCHAR(50),
    "KEY" VARCHAR(100),
    "VALUE" VARCHAR(100)
);

CREATE TYPE "sap.pa.apl.base::BASE.T.INDICATORS" AS TABLE (
    "OID" VARCHAR(50),
    "VARIABLE" VARCHAR(255),
    "TARGET" VARCHAR(255),
    "KEY" VARCHAR(100),
    "VALUE" NCLOB,
    "DETAIL" NCLOB
);

CREATE PROCEDURE "GET_HAS_APL"(OUT has_apl BOOLEAN)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
VARIABLE CACHE ON has_apl ENABLE
DETERMINISTIC
AS BEGIN
	SELECT CASE WHEN COUNT(*)>0 THEN TRUE ELSE FALSE END into has_apl FROM "M_PLUGIN_STATUS" WHERE "PLUGIN_NAME"='sap_afl_sdk_apl';
END;

CREATE PROCEDURE "GET_HAS_RIGHT_TO_OBJECT"(
	IN USER_NAME NVARCHAR(100),
	IN RIGHT_NAME NVARCHAR(100),
	IN SCHEMA_NAME NVARCHAR(100),
	IN OBJECT_NAME NVARCHAR(100),
	OUT has_right BOOLEAN)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
AS BEGIN
	SELECT 
		CASE 
			WHEN COUNT(*) >0 THEN TRUE
			ELSE FALSE
			END into has_right
	 FROM "SYS"."EFFECTIVE_PRIVILEGES" WHERE "USER_NAME"=:USER_NAME AND "OBJECT_NAME"=:OBJECT_NAME AND "SCHEMA_NAME"=:SCHEMA_NAME AND "PRIVILEGE"=:RIGHT_NAME;
END;

CREATE PROCEDURE "GET_HAS_SCRIPTSERVER"(OUT has_scriptserver BOOLEAN)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
VARIABLE CACHE ON has_scriptserver ENABLE
AS BEGIN
	SELECT 
		CASE 
           WHEN COUNT(*) > 0 THEN TRUE 
           ELSE FALSE 
       	END into has_scriptserver
	FROM "M_SERVICES"
	WHERE "SERVICE_NAME" = 'scriptserver' AND "ACTIVE_STATUS" = 'YES';
END;

CREATE PROCEDURE "GET_IS_HCE"(OUT is_hce BOOLEAN)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
VARIABLE CACHE ON is_hce ENABLE
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

-- Don't call this function on hce
CREATE PROCEDURE "GET_HAS_EFFECTIVE_APL_PROC"(IN proc_name NVARCHAR(1000),out has_proc BOOLEAN)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
AS BEGIN
	DECLARE nb INT;
	
	SELECT COUNT(*) into nb FROM "PUBLIC"."EFFECTIVE_PRIVILEGES" 
		WHERE "USER_NAME" = CURRENT_USER
		AND "SCHEMA_NAME" = 'SAP_PA_APL'
		AND "GRANTEE"='sap.pa.apl.base.roles::APL_EXECUTE'
		AND "OBJECT_TYPE"='PROCEDURE'
		AND "OBJECT_NAME" NOT LIKE 'APL%' 
		AND "OBJECT_NAME" LIKE '%' || :proc_name || '%';
	IF :nb > 0 THEN
		has_proc := TRUE;
	ELSE
		has_proc := FALSE;
	END IF;
END;


-- Don't call this proc on hce
CREATE PROCEDURE "GET_CAN_CALL_APL_PROC"(IN proc_name NVARCHAR(1000),OUT can_call NVARCHAR(100))
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
AS BEGIN
	DECLARE nb INT;
	DECLARE has_effective_call BOOLEAN;

	SELECT COUNT(*) into nb FROM granted_roles WHERE "GRANTEE"=CURRENT_USER AND "ROLE_NAME"='sap.pa.apl.base.roles::APL_EXECUTE';
	IF :nb<>1
	THEN
		can_call = 'APL_GLOBAL_ROLE_NOT_GRANTED';
	ELSE
		SELECT COUNT(*) into nb FROM "PUBLIC"."PROCEDURES" WHERE "SCHEMA_NAME" = 'SAP_PA_APL' AND "PROCEDURE_NAME"=:proc_name;
		IF :nb <>1
		THEN
			can_call = 'APL_GLOBAL_CODE_NOT_HERE';
		ELSE
			CALL "GET_HAS_EFFECTIVE_APL_PROC"(:proc_name,has_effective_call); 
			IF :has_effective_call = FALSE
			THEN
				can_call = 'APL_CODE_NOT_IN_EFFECTIVE_PRIVILEGES';
			ELSE
				can_call = 'OK';
			END IF;
		END IF;
	END IF;
END;

-- Don't call this procedure on hce
CREATE PROCEDURE "CHECK_CAN_CALL_APL_PROCEDURE"(IN proc_name NVARCHAR(1000), OUT can_call NVARCHAR(1000), OUT results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN 
	DECLARE who_am_i NVARCHAR(1000) = CURRENT_USER;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION	
	-- DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:results.insert(('CHECK_CAN_CALL_APL_PROCEDURE SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
	END;
    CALL "GET_CAN_CALL_APL_PROC"(:proc_name,can_call);

    IF :can_call = 'APL_GLOBAL_CODE_NOT_HERE'
    THEN
        :results.insert(('APL DU procedure ' || :proc_name || ' is not globally available','ISSUE','Cannot call APL DU proc ' || :proc_name));
        :results.insert(('','','FIX: If you are sure ' || :proc_name || ' is part of APL DU, reinstall APL'));
    END IF;

    IF :can_call = 'APL_GLOBAL_ROLE_NOT_GRANTED'
    THEN
        :results.insert(('User ' || :who_am_i || ' does not have the global role sap.pa.apl.base.roles::APL_EXECUTE','ISSUE','Calling ANY APL DU proc will fail due to insufficient privilege'));
        :results.insert(('','','FIX: Please call _SYS_REPO.GRANT_ACTIVATED_ROLE (''sap.pa.apl.base.roles::APL_EXECUTE'',''' || :who_am_i || ''')'));
    END IF;

    IF :can_call = 'APL_CODE_NOT_IN_EFFECTIVE_PRIVILEGES'
    THEN
        :results.insert(('Issue: APL DU proc ' || proc_name  || ' is not in the list of effective_privileges of ' || :who_am_i,'ISSUE','Calling ' || :proc_name || ' will fail due to insufficient privilege'));
        :results.insert(('','','FIX: force registration of APL DU (HCO_PA_APL.tgz) with hdablm'));
    END IF;

    IF :can_call  = 'OK'
    THEN
        :results.insert(('Looks like ' || :who_am_i || ' has everything to call APL DU proc ' || :proc_name,'OK',''));
    ELSE
        :results.insert(('Looks like ' || :who_am_i || ' CANNOT call APL DU proc ' || :proc_name,'ISSUE',''));
    END IF;
END;


-- This type is not an APL type but is used in the check

CREATE TYPE "apl_check:KNOWN_VERSION_TABLES_TYPES_APIS" AS TABLE (
	"VERSION" NVARCHAR(100),
	"TABLES_TYPES" INTEGER,
	"DU_APIS" INTEGER);

CREATE PROCEDURE "CHECK_APIS"(IN du_version INTEGER,OUT results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS 
BEGIN
	DECLARE nb_apl_tables_types INTEGER;
	DECLARE nb_apl_du_apis INTEGER;
	DECLARE known_versions "apl_check:KNOWN_VERSION_TABLES_TYPES_APIS";
    DECLARE ref_version NVARCHAR(100);
	DECLARE ref_nb_apl_tables_types INTEGER;
	DECLARE ref_nb_apl_dus INTEGER;

	SELECT COUNT(*) into nb_apl_tables_types FROM "M_TABLES" WHERE "SCHEMA_NAME" = 'SAP_PA_APL' AND "TABLE_NAME" LIKE 'sap.pa.apl.%';
	SELECT COUNT(*)  into nb_apl_du_apis FROM  (SELECT DISTINCT "PROCEDURE_NAME" FROM "PUBLIC"."PROCEDURES" WHERE "SCHEMA_NAME" = 'SAP_PA_APL' AND "PROCEDURE_NAME" LIKE 'sap.pa.apl.%' UNION ALL SELECT DISTINCT "FUNCTION_NAME" FROM "PUBLIC"."FUNCTIONS" WHERE "SCHEMA_NAME" = 'SAP_PA_APL' AND "FUNCTION_NAME" LIKE 'sap.pa.apl.%') ;
	
	if :du_version=-1
	THEN
		:results.insert(('This is an HCE version of APL','','there is no potential issue on du packaging to check'));
		:results.insert(('# of APL tables and types','',:nb_apl_tables_types || ' to be checked'));
		:results.insert(('# of SQL APL APIS','',:nb_apl_du_apis || ' to be checked'));
	ELSE
		-- we build manually a partial list of known version of APL
		:known_versions.insert(('1901','104','73'));
		:known_versions.insert(('1904','88','73'));
		:known_versions.insert(('2006','88','74'));
		:known_versions.insert(('2113','167','150'));
		:known_versions.insert(('2123','170','154'));
		:known_versions.insert(('2203','170','154'));
		:known_versions.insert(('2225','185','170'));
		:known_versions.insert(('2303','185','170'));
		:known_versions.insert(('2307','186','171'));
		:known_versions.insert(('2309','188','174'));
		:known_versions.insert(('2311','190','176'));
		:known_versions.insert(('2313','190','176'));
		:known_versions.insert(('2321','190','176'));
		:known_versions.insert(('2325','137','183'));
		:known_versions.insert(('2402','164','183'));
		:known_versions.insert(('2403','164','183'));
		:known_versions.insert(('2405','164','183'));
		:known_versions.insert(('2407','164','183'));
		:known_versions.insert(('2409','164','184'));
		:known_versions.insert(('2411','164','184'));
		:known_versions.insert(('2413','164','184'));
		:known_versions.insert(('2415','164','184'));
		:known_versions.insert(('2419','164','184'));
		:known_versions.insert(('2421','164','184'));
		:known_versions.insert(('2423','164','184'));
		:known_versions.insert(('2425','171','192'));
		:known_versions.insert(('2502','171','192'));
		:known_versions.insert(('2504','171','192'));
		:known_versions.insert(('2506','171','192'));
		:known_versions.insert(('2508','171','192'));
		:known_versions.insert(('2510','171','192'));
		:known_versions.insert(('2512','171','192'));
		:known_versions.insert(('2514','171','192'));
		-- we search if the current version is a well known version
		SELECT "VERSION","TABLES_TYPES","DU_APIS" into ref_version,ref_nb_apl_tables_types,ref_nb_apl_dus DEFAULT 'NotFound',-1,-1 FROM :known_versions WHERE "VERSION" = :du_version;
		IF :ref_version = 'NotFound'
		THEN
			:results.insert(('This is an unlisted On Premise version of APL','',:du_version));
			SELECT "VERSION","TABLES_TYPES","DU_APIS" into ref_version,ref_nb_apl_tables_types,ref_nb_apl_dus  FROM :known_versions WHERE "VERSION" = (SELECT MAX("VERSION") FROM:known_versions);
			-- we check if the current version is more recent than the last known version
			-- in such case, the # of tables and types and the # of APL DU APIs should be at least the same as the last known version
			IF :du_version>:ref_version
			THEN
				:results.insert(('This is a new unknown version of APL','',:du_version));
				IF :nb_apl_tables_types >= :ref_nb_apl_tables_types
				THEN
					:results.insert(('Sensible # of APL tables and types','OK',:nb_apl_tables_types || ' >= ' || :ref_nb_apl_tables_types));
				ELSE
					:results.insert(('# of APL tables and types','ISSUE',:nb_apl_tables_types || ' is suspicously low. It should be at least ' || :ref_nb_apl_tables_types));
				END IF;
				IF :nb_apl_du_apis >= :ref_nb_apl_dus
				THEN
					:results.insert(('Sensible # of APL DU APIS','OK',:nb_apl_du_apis || ' >= ' || :ref_nb_apl_dus));
				ELSE
					:results.insert(('# of APL DU APIS','ISSUE',:nb_apl_du_apis || ' is suspicously low. It should be at least ' || :ref_nb_apl_dus));
				END IF;
			ELSE
				:results.insert(('This is an unlisted old On Premise version of APL','',:du_version));
				:results.insert(('# of APL tables and types','',:nb_apl_tables_types || ' to be checked'));
				:results.insert(('# of APL APL DU APIS','',:nb_apl_du_apis || ' to be checked'));
			END IF;
		ELSE
			:results.insert(('This is an On Premise well known version of APL','','Matching version is ' || :ref_version));
			IF :nb_apl_tables_types <> :ref_nb_apl_tables_types
			THEN
				:results.insert(('Bad # of APL tables and types','ISSUE',:nb_apl_tables_types || ' instead of ' || :ref_nb_apl_tables_types));
			ELSE
				:results.insert(('Good # of APL tables and types','OK',:nb_apl_tables_types || ' is the expected number'));
			END IF;
			IF :nb_apl_du_apis <> :ref_nb_apl_dus
			THEN
				:results.insert(('Bad # of APL DU APIS','ISSUE',:nb_apl_du_apis || ' instead of ' || :ref_nb_apl_dus));
			ELSE
				:results.insert(('Good # of APL DU APIS','OK',:nb_apl_du_apis || ' is the expected number'));
			END IF;
		END IF;
	END IF;
END;

CREATE FUNCTION "HAS_APL"()
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

CREATE FUNCTION "CLEAN_PARSER_PROOFING"(IN input NVARCHAR(5000))
RETURNS output NVARCHAR(5000)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
DETERMINISTIC 
AS BEGIN
	output = REPLACE(REPLACE(REPLACE(:input,'<->','-'||'-'),'</>','/' || '/'),'<CACHE_SCHEMA>','APL_'||'CACHE_SCHEMA>');
END;


-- need SERVICE ADMIN & MONITORING rights to fully work

CREATE PROCEDURE "CHECK_SYSTEM_INFOS"(OUT results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE lcm_components "CHECK_RESULTS_T";
	DECLARE tenant_and_users "CHECK_RESULTS_T";
	DECLARE is_hce BOOLEAN;

	CALL "GET_IS_HCE"(is_hce);
	IF :is_hce = FALSE
	THEN
		EXECUTE IMMEDIATE 'SELECT "SP_DESCRIPTION" AS "KEY",'''' AS "STATUS","VERSION" || ''.'' || "VERSION_SP" || ''.'' || "VERSION_PATCH" AS "DETAILS" FROM "LCM_SOFTWARE_COMPONENTS" ORDER BY "SP_DESCRIPTION"' into lcm_components;
		:results.insert(('subsection:','|Description| |Version|','Installed components'));
		:results.insert(:lcm_components);	
	END IF;

	:results.insert(('subsection:','|Name| | |','Active plugins'));
	plugins = SELECT DISTINCT("PACKAGE_NAME") AS "KEY",'' AS "STATUS",'' AS "DETAILS" FROM M_PLUGIN_STATUS ORDER BY "KEY";
	:results.insert(:plugins);

	system_overview= SELECT "SECTION"||':'||"NAME",LOWER("STATUS"),"VALUE" FROM "M_SYSTEM_OVERVIEW" ORDER BY 1;
	:results.insert(('subsection:','|Info|Status|Details|','System Overview'));
	:results.insert(:system_overview);

	host_informations = SELECT "HOST",LOWER("KEY"),"VALUE" FROM m_host_information WHERE "KEY" IN ('container','cpu_summary','daemon_active','hw_model','mem_phys','os_name','net_realhostname','os_user', 'sap_retrieval_path','sid','sapsystem') ORDER BY "HOST","KEY";
	:results.insert(('subsection:','|Host|Info|Value|','Host informations'));
	:results.insert(:host_informations);

	databases = select "DATABASE_NAME",'ACTIVE_STATUS:'||"ACTIVE_STATUS" || ':' || "ACTIVE_STATUS_DETAILS","DESCRIPTION" from m_databases ORDER BY "DATABASE_NAME";
	:results.insert(('subsection:','|Name|Status|Description|','Databases'));
	:results.insert(:databases);

	database_history = SELECT "VERSION",'',TO_NVARCHAR("INSTALL_TIME",'YYYY-MM-DD HH24:MI:SS') FROM "M_DATABASE_HISTORY" ORDER BY "INSTALL_TIME" DESC;
	:results.insert(('subsection:','|Version| | Date|','Database history'));
	:results.insert(:database_history);

	services = SELECT "HOST","SERVICE_NAME"||':'||"ACTIVE_STATUS","PORT"||':'||"SQL_PORT" from m_services ORDER BY "HOST","SERVICE_NAME";
	:results.insert(('subsection:','|Host|Service:status|Port:SQL Port|','Services'));
	:results.insert(:services);

	current_database = SELECT "SYSTEM_ID","DATABASE_NAME","USAGE" FROM "M_DATABASE" ORDER BY "HOST","SYSTEM_ID","DATABASE_NAME";
	:results.insert(('subsection:','|SID|Name|Usage|','Current database'));
	:results.insert(:current_database);

	-- experimental : Multitenancy On HANA Cloud
	IF :is_hce = TRUE
	THEN
		EXECUTE IMMEDIATE 'SELECT ''Users of tenant '' AS "KEY","TENANT_NAME" AS "STATUS",COUNT(*) || '':'' || SUBSTRING(STRING_AGG("OBJECT_NAME",'',''),1,200) AS "DETAILS" FROM "TENANT_OBJECTS" WHERE "OBJECT_TYPE"=''USER'' GROUP BY "TENANT_NAME"' into tenant_and_users;
		IF IS_EMPTY(:tenant_and_users)
		THEN
			:results.insert(('No tenant and tenant users found','Standard HANA Cloud instance',''));
		ELSE
			:results.insert(('HANA Cloud instance with Native MultiTenancy detected','WARNING',"CLEAN_PARSER_PROOFING"('To be able to run procedure mode of APL, tenant users must do: set <CACHE_SCHEMA>=CURRENT_USER')));
			:results.insert(:tenant_and_users);
		END IF;
	END IF;

	usage = SELECT "FUNCTION_NAME",CAST("EXECUTION_COUNT" AS NVARCHAR(255)),TO_NVARCHAR("LAST_EXECUTION_TIMESTAMP",'YYYY-MM-DD HH24:MI:SS') from M_AFL_FUNCTIONS WHERE "AREA_NAME"='APL_AREA' ORDER BY "EXECUTION_COUNT" DESC;
	:results.insert(('subsection:','','Most used APL functions since restart'));
	if NOT IS_EMPTY(:usage)
	THEN
		:results.insert(:usage);
	ELSE
		:results.insert(('No APL function has been called since last restart','',''));
	END IF;

	procedures_cache = SELECT 'Cached SQL wrappers',"SCHEMA_NAME",CAST(COUNT(*) AS NVARCHAR) from PROCEDURES WHERE PROCEDURE_NAME LIKE 'APL!_P!_%' ESCAPE '!' GROUP BY "SCHEMA_NAME";
	:results.insert(('subsection:','','Content of APL cache'));
	IF NOT IS_EMPTY(:procedures_cache)
	THEN
		:results.insert(:procedures_cache);
	ELSE
		:results.insert(('No SQL wrappers detected in cache','',''));
	END IF;
	types_cache = SELECT 'Cached types',"SCHEMA_NAME",CAST(COUNT(*) AS NVARCHAR) from TABLES WHERE TABLE_NAME LIKE 'APL!_T!_%' ESCAPE '!' GROUP BY "SCHEMA_NAME";
	IF NOT IS_EMPTY(:types_cache)
	THEN
		:results.insert(:types_cache);
	ELSE
		:results.insert(('No types detected in cache','',''));
	END IF;

	memory_usage= SELECT "SERVICE_NAME","CATEGORY",'EXCL_HEAPMEM_USED:'||TO_DECIMAL(ROUND(EXCLUSIVE_SIZE_IN_USE/(1024*1024),2),10,2)||'MB:EXCL_MAX_SINGLE_ALLOCATION_SIZE:'|| TO_DECIMAL(ROUND(EXCLUSIVE_MAX_SINGLE_ALLOCATION_SIZE/(1024*1024),2),10,2)||'MB:EXCL_PEAK_ALLOCATION_SIZE:'|| TO_DECIMAL(ROUND(EXCLUSIVE_PEAK_ALLOCATION_SIZE/(1024*1024),2),10,2)||'MB' AS "DETAILS" from "SYS"."M_HEAP_MEMORY" M,"SYS"."M_SERVICE_MEMORY" S WHERE CATEGORY IN( 'Pool/AFL_SDK/APL','Pool/malloc/libaflapl.so') AND M.PORT = S.PORT ORDER BY "SERVICE_NAME","CATEGORY";
	:results.insert(('subsection:','','Memory usage of APL since restart'));
	IF NOT IS_EMPTY(:memory_usage)
	THEN
		:results.insert(:memory_usage);
	ELSE
		:results.insert(('No APL memory usage since last restart','',''));
	END IF;
END;

CREATE PROCEDURE "CHECK_SUPPORT_STATEMENTS_ON_PREMISE"(OUT results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE instance_number NVARCHAR(100);
	DECLARE database_name NVARCHAR(100);
	DECLARE APL_version NVARCHAR(100);
	DECLARE sap_retrieval_path NVARCHAR(100);
	DECLARE hana_shared_sid NVARCHAR(100);
	DECLARE hostname NVARCHAR(100);
	DECLARE real_host_name NVARCHAR(100);
    DECLARE regi_port NVARCHAR(100);

	SELECT "HOST","DATABASE_NAME" into hostname,database_name FROM "M_DATABASE";
	SELECT "VALUE" into instance_number FROM "M_SYSTEM_OVERVIEW" WHERE UPPER("SECTION")='SYSTEM' AND UPPER("NAME")='INSTANCE NUMBER' ;
	EXECUTE IMMEDIATE 'SELECT "VERSION"|| ''.''|| "VERSION_SP" || ''.'' || "VERSION_PATCH" FROM "LCM_SOFTWARE_COMPONENTS" WHERE "COMPONENT_NAME"=''sap_afl_sdk_apl''' into APL_version DEFAULT '????';

	-- issue how to deal with several hosts ?
	SELECT "VALUE" into sap_retrieval_path FROM m_host_information WHERE "KEY"='sap_retrieval_path' LIMIT 1;
	SELECT "VALUE" into real_host_name FROM m_host_information WHERE "KEY"='net_realhostname' LIMIT 1;

	SELECT "SQL_PORT" into regi_port FROM "M_SERVICES" WHERE "SERVICE_NAME"='indexserver' AND "HOST"=:hostname;
	
	hana_shared_sid = '/hana/shared/' || :database_name;

	:results.insert(('section:','','Some support statements **valid only in this instance**'));

	:results.insert(('subsection:','','Installation and upgrade of APL'));
	:results.insert(('Install apl','First install',"CLEAN_PARSER_PROOFING"(:hana_shared_sid || '/hdblcm/hdblcm <->action=update_components <->components=sap_afl_sdk_apl <->system_user=SYSTEM <->component_dirs=<extracted APL archive>/installer')));
	:results.insert(('Reinstall apl','forcing full reinstall',"CLEAN_PARSER_PROOFING"(:hana_shared_sid || '/hdblcm/hdblcm <->action=update_components <->components=sap_afl_sdk_apl <->system_user=SYSTEM <->ignore=check_version <->component_dirs=<extracted APL archive>/installer')));
	
	:results.insert(('subsection:','','Connection to HANA instance'));
	:results.insert(('Connect to system db using hdbsql','server side', :hana_shared_sid ||  '/hdbclient/hdbsql -i ' || instance_number || ' -d SYSTEMDB -u SYSTEM'));	
	:results.insert(('Connect to tenant using hdbsql','server side',:hana_shared_sid ||  '/hdbclient/hdbsql -i ' || :instance_number || ' -d '|| :database_name || ' -u SYSTEM'));	
	:results.insert(('Connect to system db using hdbsql','client side (experimental)','hdbsql -n ' || real_host_name || ' -i ' || :instance_number || ' -d SYSTEMDB -u SYSTEM'));	
	:results.insert(('Connect to tenant using hdbsql','client side (experimental)','hdbsql -n ' || real_host_name || ' -i ' || :instance_number || ' -d '|| :database_name || ' -u SYSTEM'));	
		
	:results.insert(('subsection:','','Post Install step'));
	:results.insert(('Add a script server','to database ' || :database_name,:hana_shared_sid || '/hdbclient/hdbsql -i ' || :instance_number || ' -d SYSTEMDB -u SYSTEM "ALTER DATABASE ' || :database_name || ' ADD ''scriptserver''"'));
	
	:results.insert(('subsection:','','APL files on server'));
	:results.insert(('List plugin folders on server','','ls -la ' || :hana_shared_sid ||  '/exe/linuxx86_64/plugins'));
	:results.insert(('List active APL files on server','','ls -la ' || :hana_shared_sid ||  '/exe/linuxx86_64/plugins/sap_afl_sdk_apl_' || :APL_version || '*'));
	:results.insert(('List active APL DU on server','','ls -la ' || :hana_shared_sid || '/global/hdb/auto_content/HCO_PA_APL.tgz'));
	:results.insert(('List all APL DUs on server','','find ' || :hana_shared_sid || ' -name HCO_PA_APL.tgz -ls'));
	
	:results.insert(('subsection:','','HANA Traces'));
	:results.insert(('List traces on server','of database '|| :database_name,'ls -la '||:sap_retrieval_path || 'trace/DB_' || :database_name ));
	:results.insert(('List other traces on server',''|| :database_name,'ls -la '||:sap_retrieval_path || 'trace' ));

	:results.insert(('subsection:','','Resynchronize APL DU in HANA repository'));
	:results.insert(('hdbupdrep','force update '|| :database_name || '''s DU repository',"CLEAN_PARSER_PROOFING"(:hana_shared_sid ||  '/global/hdb/install/bin/hdbupdrep <->ignore=check_version <->sid=' || :database_name || ' <->system_user=SYSTEM <->delivery_unit=/hana/shared/'||:database_name||'/global/hdb/auto_content/HCO_PA_APL.tgz')));

	:results.insert(('subsection:','','Reinstall APL DU with Application Life Cycle Management'));
	:results.insert(('Application Life Cycle Management Ux','client side secure (exp)',"CLEAN_PARSER_PROOFING"('https:</>' || :real_host_name ||':4300/sap/hana/xs/lm/index.html?page=HomeTab')));
	:results.insert(('Application Life Cycle Management Ux','client side unsecure (exp)',"CLEAN_PARSER_PROOFING"('https:</>' || :real_host_name ||':8000/sap/hana/xs/lm/index.html?page=HomeTab')));

	:results.insert(('subsection:','','Reinstall APL DU with hdbalm'));
	:results.insert(('hdbalm: list registered DUs','server side',:hana_shared_sid || '/hdbclient/hdbalm -h localhost -p 8000 -u SYSTEM du list'));
	:results.insert(('hdbalm: get infos about APL DU','server side',:hana_shared_sid || '/hdbclient/hdbalm -h localhost -p 8000 -u SYSTEM du get HCO_PA_APL sap.com'));
	:results.insert(('hdbalm: import APL DU','server side',:hana_shared_sid || '/hdbclient/hdbalm -h localhost -p 8000 -u SYSTEM import /hana/shared/'||:database_name||'/global/hdb/auto_content/HCO_PA_APL.tgz'));

	:results.insert(('subsection:','','Reinstall APL DU with regi'));
	:results.insert(('regi: list APL DU','server side',"CLEAN_PARSER_PROOFING"(:hana_shared_sid || '/hdbclient/regi <->user=SYSTEM <->host=localhost:' || :regi_port || ' <->database=' || :database_name || ' list du <->password=<system password> ')));	
	:results.insert(('regi: list DUs','server side',"CLEAN_PARSER_PROOFING"(:hana_shared_sid || '/hdbclient/regi <->user=SYSTEM <->host=localhost:' || :regi_port || ' <->database=' || :database_name || ' list dus <->password=<system password> ')));
	:results.insert(('regi: list sections of APL DU','server side',"CLEAN_PARSER_PROOFING"(:hana_shared_sid || '/hdbclient/regi <->user=SYSTEM <->host=localhost:' || :regi_port || ' <->database=' || :database_name || ' list du HCO_PA_APL <->password=<system password> ')));
	:results.insert(('regi: show infos about APL DU','server side',"CLEAN_PARSER_PROOFING"(:hana_shared_sid || '/hdbclient/regi <->user=SYSTEM <->host=localhost:' || :regi_port || ' <->database=' || :database_name || ' show du HCO_PA_APL <->vendor=sap.com <->password=<system password> ')));
	:results.insert(('regi: show status of APL DU','server side',"CLEAN_PARSER_PROOFING"(:hana_shared_sid || '/hdbclient/regi <->user=SYSTEM <->host=localhost:' || :regi_port || ' <->database=' || :database_name || ' show dustatus HCO_PA_APL <->vendor=sap.com <->password=<system password> ')));
	:results.insert(('regi: test reimport of active APL DU','server side',"CLEAN_PARSER_PROOFING"(:hana_shared_sid || '/hdbclient/regi <->user=SYSTEM <->host=localhost:' || :regi_port || ' <->database=' || :database_name || ' import du ' || :hana_shared_sid ||  '/global/hdb/auto_content/HCO_PA_APL.tgz <->forceremove=1 <->determinexrefs=1 -v -l <->onlytestimport=1 <->password=<system password>')));
	:results.insert(('regi: reimport active APL DU','server side',"CLEAN_PARSER_PROOFING"(:hana_shared_sid || '/hdbclient/regi <->user=SYSTEM <->host=localhost:' || :regi_port || ' <->database=' || :database_name || ' import du ' || :hana_shared_sid ||  '/global/hdb/auto_content/HCO_PA_APL.tgz <->forceremove=1 <->determinexrefs=1 -v -l <->password=<system password>')));	
	:results.insert(('regi: test import of APL DU','server side',"CLEAN_PARSER_PROOFING"(:hana_shared_sid || '/hdbclient/regi <->user=SYSTEM <->host=localhost:' || :regi_port || ' <->database=' || :database_name || ' import du ' || :hana_shared_sid ||  '/exe/linuxx86_64/plugins/sap_afl_sdk_apl_' || :APL_version || '*/auto_content/HCO_PA_APL.tgz <->forceremove=1 <->determinexrefs=1 -v -l <->onlytestimport=1 <->password=<system password>')));
	:results.insert(('regi: import of APL DU','server side',"CLEAN_PARSER_PROOFING"(:hana_shared_sid || '/hdbclient/regi <->user=SYSTEM <->host=localhost:' || :regi_port || ' <->database=' || :database_name || ' import du ' || :hana_shared_sid ||  '/exe/linuxx86_64/plugins/sap_afl_sdk_apl_' || :APL_version || '*/auto_content/HCO_PA_APL.tgz <->forceremove=1 <->determinexrefs=1 -v -l <->password=<system password>')));	

	:results.insert(('subsection:','','DANGER ZONE'));
	:results.insert(('hdblcm: uninstall APL - DANGER ZONE !','server side',"CLEAN_PARSER_PROOFING"(:hana_shared_sid || '/hdblcm/hdblcm <->action=uninstall <->components=sap_afl_sdk_apl ')));
	:results.insert(('hdbalm: undeploy APL DU - DANGER ZONE !','server side',:hana_shared_sid || '/hdbclient/hdbalm -h localhost -p 8000 -u SYSTEM du undeploy HCO_PA_APL sap.com'));
	:results.insert(('regi: full undeploy of APL DU - DANGER ZONE!!','server side',"CLEAN_PARSER_PROOFING"(:hana_shared_sid || '/hdbclient/regi <->user=SYSTEM <->host=localhost:' || :regi_port || ' <->database=' || :database_name || ' undeploy HCO_PA_APL <->vendor=sap.com <->password=<system password>')));	
END;

CREATE PROCEDURE "CHECK_SUPPORT_STATEMENTS_HCE"(OUT results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE instance_number NVARCHAR(100);
	DECLARE database_name NVARCHAR(100);
	DECLARE APL_version NVARCHAR(100);
	DECLARE hana_platform NVARCHAR(100);
	DECLARE hana_shared_sid NVARCHAR(100);
	DECLARE hostname NVARCHAR(100);

	SELECT "HOST","DATABASE_NAME" into hostname,database_name FROM "M_DATABASE";
	SELECT "VALUE" into hana_platform DEFAULT '' FROM "M_PLUGIN_MANIFESTS" WHERE "PLUGIN_NAME"='SAP_AFL_SDK_APL' AND "KEY"='platform';
	SELECT "VALUE" into instance_number FROM "M_SYSTEM_OVERVIEW" WHERE UPPER("SECTION")='SYSTEM' AND UPPER("NAME")='INSTANCE NUMBER' ;
	apl_version='pouet';


	:results.insert(('section:','','Some support statements **valid only in this instance**'));

	:results.insert(('subsection:','','Connection to HANA instance'));
	:results.insert(('Connect to system db using hdbsql','server side','/usr/sap/'||:database_name||'/HDB'||:instance_number||'/exe/hdbsql -i ' || instance_number || ' -d SYSTEMDB -u SYSTEM'));	
	:results.insert(('Connect to tenant using hdbsql','server side','/usr/sap/'||:database_name||'/HDB'||:instance_number||'/exe/hdbsql -i ' || :instance_number || ' -d '|| :database_name || ' -u SYSTEM'));	
	:results.insert(('Connect to system db using hdbsql','client side (experimental)','hdbsql -n ' || :hostname || ' -i ' || :instance_number || ' -d SYSTEMDB -u SYSTEM'));	
	:results.insert(('Connect to tenant using hdbsql','client side (experimental)','hdbsql -n ' || :hostname || ' -i ' || :instance_number || ' -d '|| :database_name || ' -u SYSTEM'));	
		
	:results.insert(('subsection:','','Post Install step'));
	:results.insert(('Add a script server','to database ' || :database_name,'/usr/sap/'||:database_name||'/HDB'||:instance_number||'/exe/hdbsql -i ' || :instance_number || ' -d SYSTEMDB -u SYSTEM "ALTER DATABASE ' || :database_name || ' ADD ''scriptserver''"'));
	
	:results.insert(('subsection:','','APL files on server'));
	:results.insert(('List plugin folders on server','','ls -la /hana/shared/'||:database_name||'/exe/'||:hana_platform||'/plugins'));
	:results.insert(('List APL files on server','','ls -la /hana/shared/'||:database_name||'/exe/'||:hana_platform||'/plugins/sap_afl_sdk_apl*'));
	:results.insert(('List APL SQLautocontent on server','','ls -la /hana/shared/'||:database_name||'/exe/'||:hana_platform||'/plugins/sap_afl_sdk_apl*/aflpm_autoexec*.sql'));
	
	:results.insert(('subsection:','','HANA Traces'));
	:results.insert(('List traces on server','of database '|| :database_name,'ls -la /hana/mounts/trace/hana/DB_' || :database_name ));
	:results.insert(('List other traces on server',''|| '','ls -la /hana/mounts/trace/hana' ));
END;

CREATE PROCEDURE "CHECK_SUPPORT_STATEMENTS"(OUT results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE is_hce BOOLEAN;

	"GET_IS_HCE"(is_hce);
	IF :is_hce = TRUE
	THEN
		CALL "CHECK_SUPPORT_STATEMENTS_HCE"(:results);
	ELSE
		CALL "CHECK_SUPPORT_STATEMENTS_ON_PREMISE"(:results);
	END IF;
END;


CREATE PROCEDURE "CHECK_INSTALL"(OUT results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE status_1 NVARCHAR(1000);
	DECLARE status_2 NVARCHAR(1000);
	DECLARE text_1 NVARCHAR(1000);
	DECLARE database_name NVARCHAR(1000);
	DECLARE expected_debrief_version NVARCHAR(1000);
	DECLARE du_versions NVARCHAR(1000);
	DECLARE nb INTEGER;
	DECLARE du_version integer = -1;
	DECLARE du_date DATETIME = NULL;
	DECLARE is_hce BOOLEAN;
	DECLARE has_apl BOOLEAN;
	DECLARE has_right BOOLEAN;
	DECLARE bad_apis NCLOB;
	DECLARE manifest_results "CHECK_RESULTS_T";
	DECLARE user_name nvarchar(1000) = CURRENT_USER;
	DECLARE nb_error_text INT;
	DECLARE api_results CHECK_RESULTS_T;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:results.insert(('CHECK_APL_INSTALL SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
	END;

	CALL "GET_HAS_APL"(has_apl);
	IF :has_apl = FALSE
	THEN
		RETURN;
	END IF;
	"GET_IS_HCE"(is_hce);

	SELECT "DATABASE_NAME" into database_name FROM M_DATABASE;
	:results.insert(('section:','','Checking installation of APL in database **' || :database_name || '**'));

	:results.insert(('subsection:','|Check|Status|Details|','Global status of APL plugin'));
	SELECT COUNT(*) into nb FROM M_PLUGIN_MANIFESTS WHERE "PLUGIN_NAME"='SAP_AFL_SDK_APL';
	IF :nb = 0
	THEN
		:results.insert(('No APL manifest','ISSUE','APL plugin is probably not registered (no manifest)'));
	ELSE	
		manifest_results = SELECT 'APL Manifest' AS "KEY","KEY" AS "STATUS","VALUE" AS "DETAILS" FROM "M_PLUGIN_MANIFESTS" WHERE "PLUGIN_NAME"='SAP_AFL_SDK_APL' ORDER BY "STATUS";
		:results.insert(:manifest_results);
	END IF;

	SELECT COUNT(*) into nb_error_text FROM "M_PLUGIN_STATUS" WHERE UPPER("PLUGIN_NAME")='SAP_AFL_SDK_APL' AND ((TRIM("AREA_STATUS")<>'REGISTRATION SUCCESSFUL') OR TRIM("PACKAGE_STATUS")<>'REGISTRATION SUCCESSFUL');
	if :nb_error_text > 0
	THEN
		:results.insert(('Bad high level status of APL AFL registration process','ISSUE','Missing status REGISTRATION SUCCESSFUL in table M_PLUGIN_STATUS'));
		:results.insert(('Here are traces of previous failing registration process of high level APL API','WARNING','Check the content of the table M_PLUGIN_STATUS'));
		registration_trace = SELECT 'Error text from previous registration process failures' AS "KEY",'WARNING/ERROR' AS "STATUS",SUBSTR("ERROR_TEXT",0,1000) || ':' || "AREA_STATUS" || ':' || "PACKAGE_STATUS" AS "DETAILS" FROM "M_PLUGIN_STATUS" WHERE UPPER("PLUGIN_NAME")='SAP_AFL_SDK_APL' AND ("AREA_STATUS"<>'REGISTRATION SUCCESSFUL' OR "PACKAGE_STATUS"<>'REGISTRATION_SUCCESSFUL');
		:results.insert(:registration_trace);
	ELSE
		:results.insert(('Good high level status of registration of APL plugin','OK','REGISTRATION SUCCESSFUL'));	
		:results.insert(('No detected issue during registration process of APL plugin','OK','REGISTRATION SUCCESSFUL'));
	END IF;

	:results.insert(('subsection:','|Check|Status|Details','Detailed registration of APL plugin'));
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
	-- KO : potential right issue with AFL_FUNCTIONS_
	-- SELECT COUNT(*) into nb FROM "SYS"."AFL_FUNCTIONS_" F,
	--    "SYS"."AFL_AREAS" A
	-- WHERE "A"."AREA_NAME"='APL_AREA'
	--AND "A"."AREA_OID" = "F"."AREA_OID";
	-- This is almost equivalent
	SELECT COUNT(distinct("FUNCTION_NAME")) into nb FROM "SYS"."AFL_FUNCTION_PARAMETERS" WHERE "AREA_NAME"='APL_AREA';
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

	:results.insert(('subsection:','|Check|Status|Details','Detailed registration of APL high level SQL procedures (APL DU or Hana Cloud SQLAutoContent)'));
	IF :is_hce = false
	THEN
		CALL "GET_HAS_RIGHT_TO_OBJECT"(CURRENT_USER,'SELECT','_SYS_REPO','DELIVERY_UNITS',has_right);
		IF :has_right = TRUE
		THEN
			-- dynamic sql because DELIVERY_UNIT table does not exist on HANA Cloud
			EXECUTE IMMEDIATE 'SELECT VERSION,LAST_UPDATE FROM "_SYS_REPO"."DELIVERY_UNITS" WHERE DELIVERY_UNIT=''HCO_PA_APL''' INTO du_version,du_date DEFAULT '-1','1964/01/16';		
			:results.insert(('APL DU Version','',:du_version));
			:results.insert(('APL DU Update date','',du_date));
		ELSE
			:results.insert(('Cannot check version of APL Delivery Unit','WARNING','Please execute: GRANT SELECT ON "_SYS_REPO"."DELIVERY_UNITS" TO ' || CURRENT_USER));
			du_version='-1';
			du_date='1964/01/16';
		END IF;
	END IF;

	SELECT STRING_AGG("ROLE_NAME",','),COUNT(*) into status_1,nb DEFAULT 'No APL role',0 FROM "ROLES" WHERE "ROLE_NAME" IN ('AFLPM_CREATOR_ERASER_EXECUTE','AFL__SYS_AFL_APL_AREA_EXECUTE','sap.pa.apl.base.roles::APL_EXECUTE');
	IF :nb <>3 
	THEN
		:results.insert(('Bad # of APL roles','ISSUE','Only ' || :status_1 || ' roles are granted. Expected AFLPM_CREATOR_ERASER_EXECUTE,AFL__SYS_AFL_APL_AREA_EXECUTE,sap.pa.apl.base.roles::APL_EXECUTE' ));
	ELSE
		:results.insert(('Good # of APL roles','OK','Expected roles '|| :status_1 || ' are granted'));
	END IF;
	SELECT COUNT(*) into nb FROM "ROLES" WHERE "ROLE_NAME"='sap.pa.apl.base.roles::APL_EXECUTE';
	IF :nb <>1 
	THEN
		:results.insert(('Missing main APL role sap.pa.apl.base.roles::APL_EXECUTE','ISSUE',:nb));
	ELSE
		:results.insert(('Main APL role sap.pa.apl.base.roles::APL_EXECUTE is declared','OK',:nb));
	END IF;
	CALL "CHECK_APIS"(:du_version,api_results);
	:results.insert(:api_results);
	IF :is_hce = FALSE
	THEN
		CALL "GET_HAS_RIGHT_TO_OBJECT"(CURRENT_USER,'SELECT','_SYS_REPO','ACTIVE_OBJECT',has_right);
		IF :has_right = TRUE
		THEN
			EXECUTE IMMEDIATE 'SELECT SUBSTR(STRING_AGG(COALESCE("DU_VERSION",''No DU version''),'',''),0,1000) AS "DU Versions",COUNT(*) AS "Nb DU Versions" FROM  (SELECT DISTINCT("DU_VERSION") FROM "_SYS_REPO"."ACTIVE_OBJECT" WHERE "DELIVERY_UNIT"=''HCO_PA_APL'' ORDER BY "DU_VERSION")' INTO du_versions,nb DEFAULT 'NO DU Version',0;
			IF :nb >1
			THEN
				:results.insert(('APL APIs are coming from several APL DUs','ISSUE',:du_versions));
			ELSE
				:results.insert(('APL APIs are coming from one APL DU','OK',:du_versions));
				if :du_versions <> :du_version
				THEN
					IF du_version <> -1
					THEN
						:results.insert(('APL APIs is not coming from expected APL DU','ISSUE',:du_versions || '<>' || du_version));
					ELSE
						:results.insert(('Cannot check APL APIs are coming from expected APL DU','WARNING',:du_versions || '<>' || du_version));
					END IF;
				ELSE
					:results.insert(('APL APIs is coming from expected APL DU','OK',:du_versions || '=' || du_version));
				END IF;
			END IF;
		ELSE
			:results.insert(('Cannot check APL APIs are coming from unique APL DU','WARNING','Please execute: GRANT SELECT ON "_SYS_REPO"."ACTIVE_OBJECT" TO ' || CURRENT_USER));
		END IF;
	END IF;
	IF :is_hce = FALSE
	THEN
		CALL "GET_HAS_RIGHT_TO_OBJECT"(CURRENT_USER,'SELECT','_SYS_REPO','ACTIVE_OBJECT',has_right);
		IF :has_right = TRUE
		THEN
			EXECUTE IMMEDIATE 'SELECT SUBSTR_REGEXPR(''\d+\.\d+\.\d+\.\d+'' IN CAST("CDATA" AS NVARCHAR(1000))) FROM "_SYS_REPO"."ACTIVE_OBJECT" WHERE "DELIVERY_UNIT"=''HCO_PA_APL'' AND "PACKAGE_ID"=''sap.pa.apl.debrief.internal.entity'' AND "OBJECT_NAME"=''EXPECTED_VERSION''' INTO expected_debrief_version DEFAULT 'No debrief';
			IF expected_debrief_version <> 'No debrief'
			THEN
				:results.insert(('Expected debrief version parsed from APL DU code','',:expected_debrief_version));
			ELSE
				:results.insert(('No debrief. Old version of APL ?','',''));
			END IF;
		ELSE
			:results.insert(('Cannot check has debrief concept','WARNING','Please execute: GRANT SELECT ON "_SYS_REPO"."ACTIVE_OBJECT" TO ' || CURRENT_USER));
		END IF;
   	ELSE
		EXECUTE IMMEDIATE 'SELECT "SAP_PA_APL"."sap.pa.apl.debrief.internal.entity::EXPECTED_VERSION"() FROM DUMMY' INTO expected_debrief_version;
		:results.insert(('Expected debrief version from running HCE SQL code','',:expected_debrief_version));
   	END IF;
	:results.insert(('status:','Done','Checking installation of APL plugin'));
END;

CREATE PROCEDURE "CHECK_KNOWN_DU_ISSUES"(OUT results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE apl_apis_available INTEGER;
	DECLARE effective_apl_apis_available INTEGER;
	DECLARE who_am_i NVARCHAR(1000) = CURRENT_USER;
	DECLARE missing_apis "CHECK_RESULTS_T";

	SELECT COUNT(*) into effective_apl_apis_available FROM "PUBLIC"."EFFECTIVE_PRIVILEGES" 
	WHERE "USER_NAME" = :who_am_i
	AND "SCHEMA_NAME" = 'SAP_PA_APL'
	AND "GRANTEE"='sap.pa.apl.base.roles::APL_EXECUTE'
	AND ("OBJECT_TYPE"='PROCEDURE'  OR "OBJECT_TYPE"='FUNCTION')
	AND "OBJECT_NAME" NOT LIKE 'APL%' 
	AND "OBJECT_NAME" IN (
		SELECT "PROCEDURE_NAME" FROM "SYS"."PROCEDURES" WHERE "SCHEMA_NAME"='SAP_PA_APL' AND "PROCEDURE_NAME" NOT LIKE 'APL%'
		UNION ALL
		SELECT "FUNCTION_NAME" FROM "SYS"."FUNCTIONS" WHERE "SCHEMA_NAME"='SAP_PA_APL' AND "FUNCTION_NAME" NOT LIKE 'APL%'
		);
	SELECT COUNT(*) into apl_apis_available FROM (
		SELECT "PROCEDURE_NAME" FROM "SYS"."PROCEDURES" WHERE "SCHEMA_NAME"='SAP_PA_APL' AND "PROCEDURE_NAME" NOT LIKE 'APL%'
		UNION ALL
		SELECT "FUNCTION_NAME" FROM "SYS"."FUNCTIONS" WHERE "SCHEMA_NAME"='SAP_PA_APL' AND "FUNCTION_NAME" NOT LIKE 'APL%'
		);
	IF :apl_apis_available <> :effective_apl_apis_available
	THEN
		:results.insert(('Effective deployment of APL DU for user ' ||  :who_am_i,'ISSUE',:effective_apl_apis_available || '<>' ||:apl_apis_available));
		missing_apis = SELECT 'Missing APL Proc' AS "KEY",'ISSUE' AS "STATUS","PROCEDURE_NAME" AS "DETAILS" FROM
		(SELECT  "PROCEDURE_NAME" 
				FROM "SYS"."PROCEDURES" 
				WHERE "SCHEMA_NAME"='SAP_PA_APL' 
				AND "PROCEDURE_NAME" NOT LIKE 'APL%' 
				UNION SELECT
				"FUNCTION_NAME" AS "PROCEDURE_NAME"
				FROM "SYS"."FUNCTIONS" 
				WHERE "SCHEMA_NAME"='SAP_PA_APL' 
				AND "FUNCTION_NAME" NOT LIKE 'APL%')
		WHERE "PROCEDURE_NAME" NOT IN (SELECT "OBJECT_NAME" FROM "PUBLIC"."EFFECTIVE_PRIVILEGES" WHERE "USER_NAME"=CURRENT_USER AND "SCHEMA_NAME"='SAP_PA_APL' AND "GRANTEE"='sap.pa.apl.base.roles::APL_EXECUTE' AND "OBJECT_TYPE" IN ('PROCEDURE','FUNCTION') AND "OBJECT_NAME" NOT LIKE 'APL%' )
		ORDER BY "PROCEDURE_NAME";
		:results.insert(:missing_apis);
		:results.insert(('','','!!! You need to redeploy APL DU using HANA studio, hdbalm or regi!!'));
	ELSE
		IF :effective_apl_apis_available = 0
		THEN
			:results.insert(('No deployment of APL DU for user ' ||  :who_am_i,'ISSUE','0 APL APIS'));
			:results.insert(('','','!!! You need to redeploy APL DU using HANA studio, hdbalm or regi!!'));
		ELSE
			:results.insert(('Effective deployment of APL DU for user ' ||  :who_am_i,'OK',:apl_apis_available || ' effective APL APIS'));
		END IF;
	END IF;
END;


CREATE PROCEDURE "CHECK_KNOWN_AUTOCONTENT_ISSUES"(OUT results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE ping_proc "PING_OUTPUT_T";
	DECLARE APLFullVersion NVARCHAR(255);
	DECLARE AutoContentFullVersion NVARCHAR(255);
	DECLARE has_scriptserver BOOLEAN;

	CALL "GET_HAS_SCRIPTSERVER"(has_scriptserver);
	IF :has_scriptserver = FALSE
	THEN
		:results.insert(('Discrepancy between versions of C++ & AutoContent cannot be checked','ISSUE','No Script Server'));
	ELSE
		EXECUTE IMMEDIATE 'CALL "SAP_PA_APL"."sap.pa.apl.base::PING"(:ping_proc)' INTO ping_proc;
		SELECT STRING_AGG("value",'.') INTO APLFullVersion FROM :ping_proc WHERE "name" LIKE 'APL.Version.%';
		SELECT "value" INTO AutoContentFullVersion default 'NoInfo' FROM :ping_proc WHERE "name"='SQLAutoContent.Version';
		IF :AutoContentFullVersion = 'NoInfo'
		THEN
			:results.insert(('Discrepancy between versions of C++ & AutoContent cannot be checked','WARNING','No AutoContent version'));
		ELSE
			IF :APLFullVersion <> :AutoContentFullVersion
			THEN
				:results.insert(('Discrepancy in versions of C++ & AutoContent','ISSUE','C++:' || :APLFullVersion || '<>AutoContent:' || :AutoContentFullVersion));
			ELSE
				:results.insert(('Versions of C++ & AutoContent are aligned','OK',:APLFullVersion));
			END IF;
		END IF;
	END IF;
END;


CREATE PROCEDURE "CHECK_STRANGE_ISSUES"(OUT results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE du_results "CHECK_RESULTS_T";
	DECLARE autocontent_results "CHECK_RESULTS_T";
	DECLARE is_hce BOOLEAN;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:results.insert(('CHECK_APL_STRANGE_ISSUES SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
	END;

	:results.insert(('subsection:','','Checking known deployment issues of APL SQL'));
	"GET_IS_HCE"(:is_hce);
	IF :is_hce = FALSE
	THEN
		CALL "CHECK_KNOWN_DU_ISSUES"(du_results);
		:results.insert(:du_results);
	ELSE
		CALL "CHECK_KNOWN_AUTOCONTENT_ISSUES"(autocontent_results);
		:results.insert(:autocontent_results);
	END IF;
	:results.insert(('status:','Done','Checking known deployment issues of APL SQL'));
END;	

CREATE PROCEDURE "CHECK_BASIC_RUNTIME"(OUT results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE nb INTEGER;
	DECLARE is_hce BOOLEAN;
	DECLARE ping_proc "PING_OUTPUT_T";
	DECLARE ping_direct "PING_OUTPUT_T";
	DECLARE can_call_ping NVARCHAR(1000);
	DECLARE can_call_ping_results "CHECK_RESULTS_T";
	DECLARE ping_results "CHECK_RESULTS_T";
	DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:results.insert(('CHECK_APL_BASIC_RUNTIME SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
	END;

	"GET_IS_HCE"(is_hce);

	:results.insert(('subsection:','','Checking APL basic run time in direct mode'));
	-- use an exec so this code can always be compiled
	EXECUTE IMMEDIATE 'CALL _SYS_AFL.APL_AREA_PING_PROC(:ping_direct)' into ping_direct;
	ping_results = SELECT 'ping direct' AS "KEY","name" AS "STATUS","value" AS "DETAILS" FROM :ping_direct ORDER BY "STATUS";
	:results.insert(:ping_results);
	:results.insert(('Calling direct PING successful','OK',''));

	:results.insert(('subsection:','','Checking APL basic run time in procedure mode'));
	IF 	is_hce = FALSE
	THEN
	    CALL "CHECK_CAN_CALL_APL_PROCEDURE"('sap.pa.apl.base::PING',can_call_ping,can_call_ping_results);
		:results.insert(:can_call_ping_results);
   	END IF;
	-- we always try to do the call : maybe we missed something
    -- use an exec so this code can always been compiled
	:results.insert(('Try to really call sap.pa.apl.base::PING','',''));
    -- use an exec so this code can always be compiled
	EXECUTE IMMEDIATE 'CALL "SAP_PA_APL"."sap.pa.apl.base::PING"(:ping_proc)' into ping_proc;
	ping_results = SELECT 'ping proc' AS "KEY","name" AS "STATUS","value" AS "DETAILS" FROM :ping_proc ORDER BY "STATUS";
    :results.insert(:ping_results);
    :results.insert(('Calling proc PING successful','OK',''));
    IF :is_hce = true 
    THEN
    	SELECT COUNT(*) into nb FROM :ping_proc WHERE "name" LIKE 'SQLAutoContent%';
    	IF :nb <>3
    	THEN
    		:results.insert(('Issue: HCE marker tags in proc PING results should be 3 and are actually','ISSUE',:nb));
    	ELSE
    		:results.insert(('Found HCE tags in proc PING results','OK',:nb));		
    	END IF;
    END IF;
	:results.insert(('status:','Done','Checking APL basic run time'));
END;

CREATE TYPE "SMALL_ADULT_T" AS TABLE (
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

CREATE TABLE "SMALL_ADULT" LIKE "SMALL_ADULT_T";

CREATE PROCEDURE "PREPARE_DATA_FOR_CHECK_TRAIN_PROCEDURE_MODE"()
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
AS BEGIN
	TRUNCATE TABLE "SMALL_ADULT";
	INSERT INTO "SMALL_ADULT" VALUES (39,'State-gov',77516,'Bachelors',13,'Never married','Adm-clerical','Not-in-family','White','Male',2174,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (50,'Self-emp-not-inc',83311,'Bachelors',13,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,13,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (38,'Private',215646,'HS-grad',9,'Divorced','Handlers-cleaners','Not-in-family','White','Male',0,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (53,'Private',234721,'11th',7,'Married civ spouse','Handlers-cleaners','Husband','Black','Male',0,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (28,'Private',338409,'Bachelors',13,'Married civ spouse','Prof-specialty','Wife','Black','Female',0,0,40,'Cuba',0);
	INSERT INTO "SMALL_ADULT" VALUES (37,'Private',284582,'Masters',14,'Married civ spouse','Exec managerial','Wife','White','Female',0,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (49,'Private',160187,'9th',5,'Married-spouse-absent','Other-service','Not-in-family','Black','Female',0,0,16,'Jamaica',0);
	INSERT INTO "SMALL_ADULT" VALUES (52,'Self-emp-not-inc',209642,'HS-grad',9,'Married civ spouse','Exec managerial','Husband','White','Male',0,0,45,'United States',1);
	INSERT INTO "SMALL_ADULT" VALUES (31,'Private',45781,'Masters',14,'Never married','Prof-specialty','Not-in-family','White','Female',14084,0,50,'United States',1);
	INSERT INTO "SMALL_ADULT" VALUES (42,'Private',159449,'Bachelors',13,'Married civ spouse','Exec managerial','Husband','White','Male',5178,0,40,'United States',1);
	INSERT INTO "SMALL_ADULT" VALUES (37,'Private',280464,'Some-college',10,'Married civ spouse','Exec managerial','Husband','Black','Male',0,0,80,'United States',1);
	INSERT INTO "SMALL_ADULT" VALUES (30,'State-gov',141297,'Bachelors',13,'Married civ spouse','Prof-specialty','Husband','Asian-Pac-Islander','Male',0,0,40,'India',1);
	INSERT INTO "SMALL_ADULT" VALUES (23,'Private',122272,'Bachelors',13,'Never married','Adm-clerical','Own-child','White','Female',0,0,30,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (32,'Private',205019,'Assoc-acdm',12,'Never married','Sales','Not-in-family','Black','Male',0,0,50,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (40,'Private',121772,'Assoc-voc',11,'Married civ spouse','Craft-repair','Husband','Asian-Pac-Islander','Male',0,0,40,NULL,1);
	INSERT INTO "SMALL_ADULT" VALUES (34,'Private',245487,'7th-8th',4,'Married civ spouse','Transport-moving','Husband','Amer-Indian-Eskimo','Male',0,0,45,'Mexico',0);
	INSERT INTO "SMALL_ADULT" VALUES (25,'Self-emp-not-inc',176756,'HS-grad',9,'Never married','Farming-fishing','Own-child','White','Male',0,0,35,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (32,'Private',186824,'HS-grad',9,'Never married','Machine-op-inspct','Unmarried','White','Male',0,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (38,'Private',28887,'11th',7,'Married civ spouse','Sales','Husband','White','Male',0,0,50,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (43,'Self-emp-not-inc',292175,'Masters',14,'Divorced','Exec managerial','Unmarried','White','Female',0,0,45,'United States',1);
	INSERT INTO "SMALL_ADULT" VALUES (40,'Private',193524,'Doctorate',16,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,60,'United States',1);
	INSERT INTO "SMALL_ADULT" VALUES (54,'Private',302146,'HS-grad',9,'Separated','Other-service','Unmarried','Black','Female',0,0,20,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (35,'Federal-gov',76845,'9th',5,'Married civ spouse','Farming-fishing','Husband','Black','Male',0,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (43,'Private',117037,'11th',7,'Married civ spouse','Transport-moving','Husband','White','Male',0,2042,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (59,'Private',109015,'HS-grad',9,'Divorced','Tech-support','Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (56,'Local-gov',216851,'Bachelors',13,'Married civ spouse','Tech-support','Husband','White','Male',0,0,40,'United States',1);
	INSERT INTO "SMALL_ADULT" VALUES (19,'Private',168294,'HS-grad',9,'Never married','Craft-repair','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (54,NULL,180211,'Some-college',10,'Married civ spouse',NULL,'Husband','Asian-Pac-Islander','Male',0,0,60,'South',1);
	INSERT INTO "SMALL_ADULT" VALUES (39,'Private',367260,'HS-grad',9,'Divorced','Exec managerial','Not-in-family','White','Male',0,0,80,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (49,'Private',193366,'HS-grad',9,'Married civ spouse','Craft-repair','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (23,'Local-gov',190709,'Assoc-acdm',12,'Never married','Protective-serv','Not-in-family','White','Male',0,0,52,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (20,'Private',266015,'Some-college',10,'Never married','Sales','Own-child','Black','Male',0,0,44,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (45,'Private',386940,'Bachelors',13,'Divorced','Exec managerial','Own-child','White','Male',0,1408,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (30,'Federal-gov',59951,'Some-college',10,'Married civ spouse','Adm-clerical','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (22,'State-gov',311512,'Some-college',10,'Married civ spouse','Other-service','Husband','Black','Male',0,0,15,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (48,'Private',242406,'11th',7,'Never married','Machine-op-inspct','Unmarried','White','Male',0,0,40,'Puerto-Rico',0);
	INSERT INTO "SMALL_ADULT" VALUES (21,'Private',197200,'Some-college',10,'Never married','Machine-op-inspct','Own-child','White','Male',0,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (19,'Private',544091,'HS-grad',9,'Married-AF-spouse','Adm-clerical','Wife','White','Female',0,0,25,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (31,'Private',84154,'Some-college',10,'Married civ spouse','Sales','Husband','White','Male',0,0,38,NULL,1);
	INSERT INTO "SMALL_ADULT" VALUES (48,'Self-emp-not-inc',265477,'Assoc-acdm',12,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (31,'Private',507875,'9th',5,'Married civ spouse','Machine-op-inspct','Husband','White','Male',0,0,43,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (53,'Self-emp-not-inc',88506,'Bachelors',13,'Married civ spouse','Prof-specialty','Husband','White','Male',0,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (24,'Private',172987,'Bachelors',13,'Married civ spouse','Tech-support','Husband','White','Male',0,0,50,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (49,'Private',94638,'HS-grad',9,'Separated','Adm-clerical','Unmarried','White','Female',0,0,40,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (25,'Private',289980,'HS-grad',9,'Never married','Handlers-cleaners','Not-in-family','White','Male',0,0,35,'United States',0);
	INSERT INTO "SMALL_ADULT" VALUES (57,'Federal-gov',337895,'Bachelors',13,'Married civ spouse','Prof-specialty','Husband','Black','Male',0,0,40,'United States',1);
END;

CREATE PROCEDURE "CHECK_TRAIN_PROCEDURE_MODE"(OUT results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN 
	DECLARE config "sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
	DECLARE header "sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
	DECLARE var_role "sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
	DECLARE var_desc "sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
	DECLARE out_log "sap.pa.apl.base::BASE.T.OPERATION_LOG";
	DECLARE out_sum "sap.pa.apl.base::BASE.T.SUMMARY";
	DECLARE out_indic "sap.pa.apl.base::BASE.T.INDICATORS";
	DECLARE model "sap.pa.apl.base::BASE.T.MODEL_BIN_OID";
	DECLARE cancall_results "CHECK_RESULTS_T";
	DECLARE who_am_i NVARCHAR(1000) = CURRENT_USER;
	DECLARE can_call_train NVARCHAR(1000);
	DECLARE nb INTEGER;
	DECLARE is_hce BOOLEAN;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION	
	-- DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:results.insert(('CHECK_TRAIN_PROCEDURE_MODE SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
	END;

	:results.insert(('subsection:','','Checking APL full train run time in procedure mode'));
	"GET_IS_HCE"(is_hce);
	
	CALL "PREPARE_DATA_FOR_CHECK_TRAIN_PROCEDURE_MODE"();

	IF :is_hce = FALSE
	THEN
	    CALL "CHECK_CAN_CALL_APL_PROCEDURE"('sap.pa.apl.base::CREATE_MODEL_AND_TRAIN',can_call_train,can_call_results);
	    :results.insert(:can_call_results);
	END IF;
    -- we always try to do the call : maybe we missed something
    -- use an exec so this code can always been compiled
	:results.insert(('Try to really call sap.pa.apl.base::CREATE_MODEL_AND_TRAIN','',''));
	:header.insert(('Oid', '#42'));
	:header.insert(('LogLevel', '8'));
	:header.insert(('ModelFormat', 'bin'));
    :header.insert(('CheckOperationConfig', 'true'));
	:config.insert(('APL/ModelType', 'binary classification',NULL));
	delete from :var_desc; -- to avoid a useless warning
	
	EXECUTE IMMEDIATE 
        'CALL "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role, ''' || :who_am_i || ''', ''SMALL_ADULT'', :model, :out_log, :out_sum, :out_indic)'
        INTO model,out_log,out_sum,out_indic 
        USING header,config,var_desc,var_role;
    SELECT COUNT(*) into nb FROM :model;
    IF :nb = 1
    THEN
        :results.insert(('Call APL DU proc sap.pa.apl.base::CREATE_MODEL_AND_TRAIN has been successful','OK',''));
    ELSE
    -- error is catched somewhere else
    END IF;
	:results.insert(('status:','Done','Checking runtime train in procedure mode'));
END;

CREATE PROCEDURE "ANALYZE_CHECKS"(
	IN full_check BOOLEAN,
	IN check_results "CHECK_RESULTS_T",
	OUT final_results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE nb_issues INTEGER = 0;
	DECLARE nb_fatal_errors INTEGER = 0;
	DECLARE check_install_ended INTEGER = 0;
	DECLARE check_deployment_issue_ended INTEGER = 0;
	DECLARE check_basic_runtime_ended INTEGER = 0;
	DECLARE check_train_ended INTEGER = 0;
	DECLARE error_message NVARCHAR(5000) = NULL;
	DECLARE check_finished_properly NVARCHAR(5000) = 'OK';
	DECLARE issues "CHECK_RESULTS_T";
	DECLARE EXIT HANDLER FOR SQLEXCEPTION	
	BEGIN
		:final_results.insert(('ANALYZE_CHECKS SQLScript error:', ::SQL_ERROR_CODE, ::SQL_ERROR_MESSAGE));
	END;

	IF IS_EMPTY(:check_results) 
	THEN
		RETURN;
	END IF;

	:final_results.insert(('section:','','Analysis of results'));
	:final_results.insert(('subsection:','','Summary of results'));
	SELECT COUNT(*) into nb_issues FROM :check_results WHERE "STATUS" IN ('ISSUE','ERROR','ACTION');
	SELECT COUNT(*) into check_install_ended FROM :check_results WHERE "KEY" = 'status:' AND "DETAILS"='Checking installation of APL plugin' AND "STATUS" ='Done';
	SELECT COUNT(*) into check_deployment_issue_ended FROM :check_results WHERE "KEY" = 'status:' AND "DETAILS"='Checking known deployment issues of APL SQL' AND "STATUS" ='Done';
	SELECT COUNT(*) into check_basic_runtime_ended FROM :check_results WHERE "KEY" = 'status:' AND "DETAILS"='Checking APL basic run time' AND "STATUS" ='Done';
	SELECT COUNT(*) into check_train_ended FROM :check_results WHERE "KEY" = 'status:' AND "DETAILS"='Checking runtime train in procedure mode' AND "STATUS" ='Done';


	if check_install_ended = 1
	then
		 :final_results.insert(('Analysis of install of APL plugin properly ended','OK',''));
	else
		SELECT Details into error_message FROM :check_results WHERE "KEY"='CHECK_APL_INSTALL SQLScript error:' LIMIT 1 ;
		:final_results.insert(('Analysis of install of APL plugin unexpectedly ended','ERROR','Reported failure is ' || :error_message)  );
		check_finished_properly = 'ERROR';
	end if; 
	if check_deployment_issue_ended = 1
	then
		:final_results.insert(('Analysis of APL deployment issue properly ended','OK',''));
	else
		SELECT details into error_message FROM :check_results WHERE "KEY"='CHECK_APL_STRANGE_ISSUES SQLScript error:' LIMIT 1;
		:final_results.insert(('Analysis of APL deploiement issue unexpectedly ended','ERROR','Reported failure is ' || :error_message)  );
		check_finished_properly = 'ERROR';
	end if;

	if :full_check = TRUE
	then
		if check_basic_runtime_ended = 1
		then
			:final_results.insert(('Analysis of APL basic runtime properly ended','OK',''));
		else
			SELECT details into error_message FROM :check_results WHERE "KEY"='CHECK_APL_BASIC_RUNTIME SQLScript error:' LIMIT 1;
			:final_results.insert(('Analysis of APL basic runtime unexpectedly ended','ERROR','Reported failure is ' || :error_message)  );
			check_finished_properly = 'ERROR';
		end if;

		if check_basic_runtime_ended = 1
		then
			:final_results.insert(('Analysis of runtime train proc properly ended','OK',''));
		else
			SELECT details into error_message FROM :check_results WHERE "KEY"='CHECK_TRAIN_PROCEDURE_MODE SQLScript error:' LIMIT 1;
			:final_results.insert(('Analysis of runtime train proc unexpectedly ended','ERROR','Reported failure is ' || :error_message)  );
			check_finished_properly = 'ERROR';
		end if;
	else
		check_finished_properly = 'ERROR';
	end if;

	if :nb_issues > 0
	then
		:final_results.insert(('There are ' || :nb_issues ||' detected issues in APL install or runtime','ERROR','Please provide this log to support'));
		issues = SELECT * FROM :check_results WHERE "STATUS" = 'ISSUE';
		:final_results.insert(:issues);
	else
		:final_results.insert(('No issue detected in APL install/runtime','OK',''));
	end if;
	if :check_finished_properly <> 'OK'
	then
		:final_results.insert(('BUT all possible tests were not done. List of detected issues may be not complete','',''));
	else
		:final_results.insert(('All tests were done. List of detected issues is supposed to be complete','',''));
	end if;
END;


CREATE PROCEDURE "GET_DU_VERSION"(OUT du_version NVARCHAR(100))
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE is_hce BOOLEAN;

	du_version = '';
	GET_IS_HCE(is_hce);
	IF :is_hce = FALSE
	THEN
		EXECUTE IMMEDIATE 'SELECT VERSION FROM "_SYS_REPO"."DELIVERY_UNITS" WHERE DELIVERY_UNIT=''HCO_PA_APL''' INTO du_version DEFAULT '';		
	END IF;
END;

CREATE PROCEDURE "CHECK_UNINSTALL"(OUT results "CHECK_RESULTS_T")
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE has_right BOOLEAN;
	DECLARE du_version NVARCHAR(1000);
	DECLARE du_date NVARCHAR(1000);
	DECLARE database_name NVARCHAR(1000);

	SELECT "DATABASE_NAME" into database_name FROM "M_DATABASE";
	:results.insert(('section:','','Checking installation of APL in database **' || :database_name || '**'));
	CALL "GET_HAS_RIGHT_TO_OBJECT"(CURRENT_USER,'SELECT','_SYS_REPO','DELIVERY_UNITS',has_right);
	IF :has_right = TRUE
	THEN
		-- dynamic sql because DELIVERY_UNIT table does not exist on HANA Cloud
		EXECUTE IMMEDIATE 'SELECT VERSION,LAST_UPDATE FROM "_SYS_REPO"."DELIVERY_UNITS" WHERE DELIVERY_UNIT=''HCO_PA_APL''' INTO du_version,du_date DEFAULT '-1','1964/01/16';		
		:results.insert(('subsection:','','informations about APL past installation'));
		:results.insert(('APL DU is detected but not the APL plugin','ISSUE','APL has been deinstalled or a backup of a HANA with APL has been restored '));
		:results.insert(('APL DU Version','',:du_version));
		:results.insert(('APL DU Update date','',du_date));
		:results.insert(('APL '||:du_version||' has been deinstalled','ACTION','Reinstall APL cf [Installation and upgrade of APL](#installation-and-upgrade-of-apl)'));
		:results.insert(('APL '||:du_version||' has been deinstalled','ACTION','or finalize uninstall of APL cf [DANGER ZONE](#danger-zone)'));
	ELSE
		:results.insert(('Cannot check version of APL Delivery Unit','WARNING','Please execute: GRANT SELECT ON "_SYS_REPO"."DELIVERY_UNITS" TO ' || CURRENT_USER));
	END IF;
END;


CREATE PROCEDURE "CHECK_FULL_INSTALL"()
LANGUAGE SQLSCRIPT 
SQL SECURITY INVOKER
AS
BEGIN
	DECLARE prerequisite_results "CHECK_RESULTS_T";
	DECLARE system_infos_results "CHECK_RESULTS_T";
	DECLARE support_statements_results "CHECK_RESULTS_T";
	DECLARE install_results "CHECK_RESULTS_T";
	DECLARE analyze_results "CHECK_RESULTS_T";
	DECLARE strange_issues_results "CHECK_RESULTS_T";
	DECLARE basic_runtime_results "CHECK_RESULTS_T";
	DECLARE train_procedure_results "CHECK_RESULTS_T";
	DECLARE who_am_i NVARCHAR(1000) = CURRENT_USER;
	DECLARE nb_issues INT;
	DECLARE has_scriptserver BOOLEAN;
	DECLARE error_message NCLOB;
	DECLARE version_hana NVARCHAR(1000);
	DECLARE version_apl NVARCHAR(1000);
	DECLARE hana_platform NVARCHAR(1000);
	DECLARE nb_platform INT;
	DECLARE is_hce BOOLEAN;
	DECLARE has_apl BOOLEAN;
	DECLARE final_results "CHECK_RESULTS_T";
	DECLARE context NVARCHAR(255);
	DECLARE output_format NVARCHAR(10);
	DECLARE report_error BOOLEAN;
	DECLARE md_output MD_OUTPUT_T;
	DECLARE du_version NVARCHAR(1000);
	DECLARE uninstall_results "CHECK_RESULTS_T";
	DECLARE ERROR_APL condition for SQL_ERROR_CODE 10001;

	"GET_HAS_APL"(has_apl);
	"GET_HAS_SCRIPTSERVER"(has_scriptserver);
	"GET_IS_HCE"(is_hce);

	SELECT "VERSION" into version_hana FROM "M_DATABASE";
	SELECT "VALUE" into version_apl DEFAULT '' FROM "M_PLUGIN_MANIFESTS" WHERE "PLUGIN_NAME"='SAP_AFL_SDK_APL' AND "KEY"='fullversion';
	SELECT "VALUE" into hana_platform DEFAULT '' FROM "M_PLUGIN_MANIFESTS" WHERE "PLUGIN_NAME"='SAP_AFL_SDK_APL' AND "KEY"='platform';
	IF :hana_platform = '' THEN
		SELECT TOP 1 "VALUE" ||' ?',count(*) into hana_platform,nb_platform DEFAULT 'unknown',0 FROM "M_PLUGIN_MANIFESTS" WHERE "KEY"='platform' GROUP BY "VALUE" ORDER BY 2 DESC;
	END IF;

	:final_results.insert(('title:','','Full check of APL installation and runtime ' || current_date || ' ' || current_time));

	:prerequisite_results.insert(('section:','','Pre-analysis'));
	:prerequisite_results.insert(('table:','|Main component|Status|Details|',''));
	IF :is_hce = FALSE 
	THEN
		:prerequisite_results.insert(('HANA On Premise','',:version_hana || ' on ' || :hana_platform));
	ELSE
		:prerequisite_results.insert(('HANA Cloud','',:version_hana || ' on ' || :hana_platform));
	END IF;

	IF :has_apl = FALSE 
	THEN
		:prerequisite_results.insert(('APL is NOT registered !!','ISSUE','no sap_afl_sdk_apl registered in M_PLUGIN_STATUS'));
	ELSE
		:prerequisite_results.insert(('APL is installed','OK',:version_apl));		
	END IF;
	IF :has_scriptserver = FALSE
	THEN
    	:prerequisite_results.insert(('Script Server is not activated !!','ISSUE','APL even if installed, cannot be called!'));
	ELSE
		IF :has_apl=FALSE
		THEN
			:prerequisite_results.insert(('Script Server is activated','OK',''));
		ELSE
			:prerequisite_results.insert(('Script Server is activated','OK','Full analysis will be done'));
		END IF;
	END IF;
	:final_results.insert(:prerequisite_results);

	IF :has_apl = TRUE
	THEN 
		CALL "CHECK_INSTALL"(:install_results);
		:final_results.insert(:install_results);
		CALL "CHECK_STRANGE_ISSUES"(:strange_issues_results);
		:final_results.insert(:strange_issues_results);
		
		:final_results.insert(('section:','','APL Run-time checks'));
		IF :has_scriptserver = TRUE
		THEN
			CALL "CHECK_BASIC_RUNTIME"(:basic_runtime_results);
			:final_results.insert(:basic_runtime_results);
			CALL "CHECK_TRAIN_PROCEDURE_MODE"(:train_procedure_results);
			:final_results.insert(:train_procedure_results);
			CALL "ANALYZE_CHECKS"(TRUE,:final_results,:analyze_results);
		ELSE
			:final_results.insert(('subsection:','',''));
			:final_results.insert(('Cannot proceed to full analysis','ISSUE',': APL runtime cannot be tested'));
			CALL "ANALYZE_CHECKS"(FALSE,:final_results,:analyze_results);
		END IF;
		:final_results.insert(:analyze_results);
	ELSE
		-- APL is not installed, but maybe it has been uninstalled
		-- and we can still provide some infos past installation
		"GET_DU_VERSION"(du_version);
		IF :du_version<>''
		THEN
			CALL "CHECK_UNINSTALL"(:uninstall_results);
			:final_results.insert(:uninstall_results);
			-- CALL "ANALYZE_CHECKS"(FALSE,:final_results,:analyze_results);
			-- :final_results.insert(:analyze_results);
		ELSE
			-- absolutely nothing
    		:final_results.insert(('Cannot proceed to analysis','ISSUE','APL is not installed'));
		END IF;
	END IF;
	:final_results.insert(('title:','','Annexes'));
	:final_results.insert(('section:','','System and HANA instance informations'));
	CALL "CHECK_SYSTEM_INFOS"(:system_infos_results);
	:final_results.insert(:system_infos_results);
	CALL "CHECK_SUPPORT_STATEMENTS"(:support_statements_results);
	:final_results.insert(:support_statements_results);
	

	-- Purpose of this SQL is to provide a full report for analysis
	-- not a short error report
	-- so default is to not emit an error
	-- except if explicitly requested by user or QA context

	-- default is to not report an error;
	report_error = FALSE;
	IF 'on'='&SIGNAL_ERROR'
	THEN
		report_error = TRUE;
	END IF;
	SELECT "VALUE" into context FROM "M_SESSION_CONTEXT" WHERE "CONNECTION_ID"=CURRENT_CONNECTION AND "KEY"='APPLICATION';

	-- default output format is md
	output_format = 'md';
	IF '&OUTPUT_FORMAT' <> '&'||'OUTPUT_FORMAT'
	THEN
	    -- there is an explicit setup
		output_format = '&OUTPUT_FORMAT';
	ELSE
		IF :context LIKE 'DBeaver%' OR :context='HDBStudio'
		THEN
		-- DBeaver has a specific output format
			output_format = 'raw';
		END IF;
	END IF;

	-- we have now report_error,output_format and context to decide how to emit the results

	if report_error = TRUE
	THEN
		SELECT COUNT(*) into nb_issues FROM :final_results WHERE "STATUS" IN ('ISSUE','ERROR','ACTION');
		IF :nb_issues > 0
		THEN
			SELECT SUBSTR('['||STRING_AGG("KEY" || ' ' || COALESCE("STATUS",'') || ' ' || COALESCE("DETAILS",'') || CHAR(10))||']',0,3000) INTO error_message FROM :final_results WHERE "STATUS" IN ('ISSUE','ERROR','ACTION');		
			SIGNAL ERROR_APL set MESSAGE_TEXT = :error_message;
		END IF;
	END IF;

	IF output_format = 'md'
	THEN
		CALL OUTPUT_AS_MD_3_FIELDS(:final_results,md_output);
		SELECT * FROM :md_output;
	ELSE 
		SELECT * FROM :final_results;
	END IF;
END;

CALL "CHECK_FULL_INSTALL"();


----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------

-- Clean everything (need to be user with high privileges again)

-- use hdbsql's macros to provide user with high privileges and its password
connect &SYSTEM_USER PASSWORD &SYSTEM_PASSWORD;
-- clean the user and the schema
DROP USER CHECK_APL CASCADE;

