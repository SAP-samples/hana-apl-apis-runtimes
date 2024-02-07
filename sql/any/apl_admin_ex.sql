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

-- Check that the APL Delivery Unit has been correctly deployed
select * from "_SYS_REPO"."DELIVERY_UNITS" where DELIVERY_UNIT='HCO_PA_APL';

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

-- sample datasets can be imported from the folder /samples/data provided in the APL tarball
-- grant access to sample datasets
grant select on SCHEMA "APL_SAMPLES" to USER_APL;

-- The HCO_PA_APL Stored Procedures use a cache in the database for storing and reusing transient but shareable and reusable DB objects (AFL wrappers, table types, etc.) 
-- The location of this HCO_PA_APL cache is based on a database schema. 
-- The default schema for this cache is SAP_PA_APL.
-- This schema can be customized, by setting a session variable APL_CACHE_SCHEMA.
-- Uncomment these 3 lines to use a common "APL_CACHE" schema for the HCO_PA_APL cache, and grant the appropriate privilege needed to be set for the USER_APL user.
-- drop SCHEMA "APL_CACHE";
-- create SCHEMA "APL_CACHE";
-- grant create any on SCHEMA "APL_CACHE" to USER_APL;

-- As part of the HCO_PA_APL Delivery Unit deployment, a new database role APL_EXECUTE has been created.
-- Granting this role allows running APL functions and running the HCO_PA_APL Stored Procedures with the default schema as a cache
call _SYS_REPO.GRANT_ACTIVATED_ROLE ('sap.pa.apl.base.roles::APL_EXECUTE','USER_APL');

-- Set the custom cache for the HCO_PA_APL Stored Procedures
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- Check granted role with USER_APL
call "SAP_PA_APL"."sap.pa.apl.base::PING"(?);

-- Purge the cache (hence the '1' parameter, where as '0' would simply browse the cache) 
call "SAP_PA_APL"."sap.pa.apl.base::CLEANUP"(1,?);
