-- ================================================================
-- APL_AREA, KEY_INFLUENCERS
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');

drop table KEY_INFLUENCERS_CONFIG;
create table KEY_INFLUENCERS_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
-- default roles are fine: all the variables but the last one are going to be input variables, the last one is the target

drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- let this table empty to use guess variables

drop table INFLUENCERS;
create table INFLUENCERS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INFLUENCERS";

drop table CONTINUOUS_GROUPS;
create table CONTINUOUS_GROUPS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.CONTINUOUS_GROUPS";

drop table OTHER_GROUPS;
create table OTHER_GROUPS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OTHER_GROUPS";

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop view V_CENSUS_VAR_EXCL;
create view V_CENSUS_VAR_EXCL as select * , "class" as "class-leak" from APL_SAMPLES.CENSUS;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;         
    config   = select * from KEY_INFLUENCERS_CONFIG;        
    var_desc = select * from VARIABLE_DESC;              
    var_role = select * from VARIABLE_ROLES;  

    "SAP_PA_APL"."sap.pa.apl.base::KEY_INFLUENCERS"(:header, :config, :var_desc,  :var_role,'USER_APL','V_CENSUS_VAR_EXCL', out_log, out_sum,out_indic,out_influencer, out_continous_groups, out_other_groups);
    
    -- store result into table
	insert into  "USER_APL"."OPERATION_LOG"     select * from :out_log;
    insert into  "USER_APL"."SUMMARY"           select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"        select * from :out_indic;
    insert into  "USER_APL"."INFLUENCERS"       select * from :out_influencer;
    insert into  "USER_APL"."CONTINUOUS_GROUPS" select * from :out_continous_groups;
    insert into  "USER_APL"."OTHER_GROUPS"      select * from :out_other_groups;

	-- show result
	select * from "USER_APL"."OPERATION_LOG";
	select * from "USER_APL"."SUMMARY";
	select * from "USER_APL"."INDICATORS";
	select * from "USER_APL"."INFLUENCERS";
	select * from "USER_APL"."CONTINUOUS_GROUPS";
	select * from "USER_APL"."OTHER_GROUPS";
    select * from "USER_APL"."INDICATORS" where KEY = 'VariableExclusionReason';
END;
