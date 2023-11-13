-- ================================================================
-- APL_AREA, PROFILE_DATA
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).



-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

drop table PROFILE_DATA_CONFIG;
create table PROFILE_DATA_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
-- default roles are adjusted: we want all variables to be considered as input variables when profiling the dataset.
insert into VARIABLE_ROLES values ('class', 'input', null,null,null);

drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- let this table empty to let the engine guess variable descriptions

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table VARIABLE_DESC_OUT;
create table VARIABLE_DESC_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header           = select * from FUNC_HEADER;             
    config           = select * from PROFILE_DATA_CONFIG;  
    variable_desc    = select * from VARIABLE_DESC;
    variable_roles    = select * from VARIABLE_ROLES;

    "SAP_PA_APL"."sap.pa.apl.base::PROFILE_DATA"(:header, :config, :variable_desc, :variable_roles, 'APL_SAMPLES','ADULT01', out_operation_log, out_summary, out_indicators, out_variable_desc);

    -- store result into table
    insert into  "USER_APL"."OPERATION_LOG"      select * from :out_operation_log;
    insert into  "USER_APL"."SUMMARY"            select * from :out_summary;
    insert into  "USER_APL"."INDICATORS"         select * from :out_indicators; 
    insert into  "USER_APL"."VARIABLE_DESC_OUT"  select * from :out_variable_desc;

	-- show result
    select * from "USER_APL"."OPERATION_LOG";
    select * from "USER_APL"."SUMMARY";
    select * from "USER_APL"."INDICATORS";
    select * from "USER_APL"."VARIABLE_DESC_OUT";
END;
