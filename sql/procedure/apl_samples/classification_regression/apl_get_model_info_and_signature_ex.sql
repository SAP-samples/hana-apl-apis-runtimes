-- ================================================================
-- APL_AREA, GET_VARIABLE_INDICATORS, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model (created by APL procedure call) in the MODEL_TRAIN_BIN table.
--  @depend(apl_createmodel_and_train_ex.sql)

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

drop table OPERATION_CONFIG;
create table OPERATION_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table PROFITCURVES;
create table PROFITCURVES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.PROFITCURVE";

drop table TRAINING_SIGNATURE;
create table TRAINING_SIGNATURE like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.TABLE_TYPE";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    modle_in = select * from MODEL_TRAIN_BIN;             
    config    = select * from OPERATION_CONFIG;          

    "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_INFO_AND_SIGNATURE"(:header, :modle_in, :config, out_summary, out_variable_roles, out_variable_desc, out_indicators, out_profitcurves, out_training_signature);
    
    -- store result into table
    insert into  "USER_APL"."SUMMARY"            select * from :out_summary;
    insert into  "USER_APL"."VARIABLE_ROLES"     select * from :out_variable_roles;
    insert into  "USER_APL"."VARIABLE_DESC"      select * from :out_variable_desc;
    insert into  "USER_APL"."INDICATORS"         select * from :out_indicators;
    insert into  "USER_APL"."PROFITCURVES"       select * from :out_profitcurves;
    insert into  "USER_APL"."TRAINING_SIGNATURE" select * from :out_training_signature;

    select * from "USER_APL"."SUMMARY";
    select * from "USER_APL"."VARIABLE_ROLES";
    select * from "USER_APL"."VARIABLE_DESC";
    select * from "USER_APL"."INDICATORS";
    select * from "USER_APL"."PROFITCURVES";
    select * from "USER_APL"."TRAINING_SIGNATURE";
END;
