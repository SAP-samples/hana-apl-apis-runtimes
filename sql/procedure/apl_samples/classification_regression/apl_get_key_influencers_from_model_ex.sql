-- ================================================================
-- APL_AREA, KEY_INFLUENCERS
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

-- Assumption 3: There's a valid and trained model (created by APL) in the MODEL_TRAIN_BIN table.
--               For instance, you have used apl_createmodel_and_train_ex.sql before
--  @depend(apl_createmodel_and_train_ex.sql)

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');

drop table USER_APL.OPERATION_CONFIG;
create table USER_APL.OPERATION_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";

drop table INFLUENCERS;
create table INFLUENCERS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INFLUENCERS";

drop table CONTINUOUS_GROUPS;
create table CONTINUOUS_GROUPS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.CONTINUOUS_GROUPS";

drop table OTHER_GROUPS;
create table OTHER_GROUPS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OTHER_GROUPS";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;         
    model_in = select * from MODEL_TRAIN_BIN;             
    config   = select * from OPERATION_CONFIG;            

    "SAP_PA_APL"."sap.pa.apl.base::GET_KEY_INFLUENCERS_FROM_MODEL"(:header, :model_in, :config, out_sum,out_indic,out_influencer, out_continous_groups, out_other_groups);
    
    -- store result into table
    insert into  "USER_APL"."SUMMARY"           select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"        select * from :out_indic;
    insert into  "USER_APL"."INFLUENCERS"       select * from :out_influencer;
    insert into  "USER_APL"."CONTINUOUS_GROUPS" select * from :out_continous_groups;
    insert into  "USER_APL"."OTHER_GROUPS"      select * from :out_other_groups;

	-- show result
    select * from "USER_APL"."SUMMARY";
    select * from "USER_APL"."INDICATORS";
    select * from "USER_APL"."INFLUENCERS";
    select * from "USER_APL"."CONTINUOUS_GROUPS";
    select * from "USER_APL"."OTHER_GROUPS";
END;
