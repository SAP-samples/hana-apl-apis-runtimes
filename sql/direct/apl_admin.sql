-- @configSQL
-- Run this as SYSTEM
connect SYSTEM password Password1;

-- Enable script server
-- 
-- For HANA multi-tenant or HANA 2.0 SP01+, update and run sql/procedure/apl_enable_scriptserver.sql
-- Otherwise:
--     alter system alter configuration ('daemon.ini', 'SYSTEM') set ('scriptserver', 'instances') = '1' with reconfigure;

-- Check that APL functions are there
select * from "SYS"."AFL_AREAS";
select * from "SYS"."AFL_PACKAGES";
select * from "SYS"."AFL_FUNCTIONS" where AREA_NAME='APL_AREA';
select "F"."SCHEMA_NAME", "A"."AREA_NAME", "F"."FUNCTION_NAME", "F"."NO_INPUT_PARAMS", "F"."NO_OUTPUT_PARAMS", "F"."FUNCTION_TYPE", "F"."BUSINESS_CATEGORY_NAME"     
from "SYS"."AFL_FUNCTIONS_" F,"SYS"."AFL_AREAS" A  
where "A"."AREA_NAME"='APL_AREA' and "A"."AREA_OID" = "F"."AREA_OID";
select * from "SYS"."AFL_FUNCTION_PARAMETERS" where AREA_NAME='APL_AREA';

-- ------------------------------------------------------
--                  !!! IMPORTANT !!!
--
-- For the sake of simplicity, the following steps and
-- the samples provided in the APL tarball make the 
-- assumption that there's a DB user known as 'USER_APL'
-- who's allowed to execute the APL functions and has
-- access to a 'APL_SAMPLES' schema. 
--
-- It's strongly advised that you only create the 
-- APL users you need, and NEVER let a default user with
-- a simple password enabled in your database.
-- ------------------------------------------------------

-- Create a HANA user known as USER_APL, who's meant to run the APL functions
drop user USER_APL cascade;
create user USER_APL password Password1;
alter user USER_APL disable password lifetime;

-- Sample datasets can be imported from the folder /samples/data provided in the APL tarball
-- Grant access to sample datasets
grant select on SCHEMA "APL_SAMPLES" to USER_APL;

-- Grant execution right on APL functions to the user USER_APL
grant AFL__SYS_AFL_APL_AREA_EXECUTE to USER_APL;
grant AFLPM_CREATOR_ERASER_EXECUTE TO USER_APL;

