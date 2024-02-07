-- ================================================================
-- APL_AREA, GET_VARIABLE_INDICATORS, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model (created by APL procedure call) in the MODEL_TRAIN_BIN table.
--  @depend(apl_createmodel_and_train_ex.sql)

connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

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

drop table USER_APL.UPDATE_CONFIG;
create table USER_APL.UPDATE_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into USER_APL.UPDATE_CONFIG values ('APL/ForgetTraining', 'true',null);

drop table USER_APL.MODEL_FORGOTTEN_BIN;
create table USER_APL.MODEL_FORGOTTEN_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table SUMMARY_FORGOTTEN;
create table SUMMARY_FORGOTTEN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table VARIABLE_DESC_FORGOTTEN;
create table VARIABLE_DESC_FORGOTTEN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";

drop table VARIABLE_ROLES_FORGOTTEN;
create table VARIABLE_ROLES_FORGOTTEN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";

drop table INDICATORS_FORGOTTEN;
create table INDICATORS_FORGOTTEN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table PROFITCURVES_FORGOTTEN;
create table PROFITCURVES_FORGOTTEN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.PROFITCURVE";

drop table TRAINING_SIGNATURE_FORGOTTEN;
create table TRAINING_SIGNATURE_FORGOTTEN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.TABLE_TYPE";

DO BEGIN     
    header         = select * from FUNC_HEADER;       
    modle_in       = select * from MODEL_TRAIN_BIN;             
    config         = select * from OPERATION_CONFIG;  
    update_config  = select * from UPDATE_CONFIG;

    "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_INFO_AND_SIGNATURE"(:header, :modle_in, :config, out_summary, out_variable_roles, out_variable_desc, out_indicators, out_profitcurves, out_training_signature);
    "SAP_PA_APL"."sap.pa.apl.base::UPDATE_MODEL"(:header,  :modle_in, :update_config, model_forgotten_bin);
    "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_INFO_AND_SIGNATURE"(:header, :model_forgotten_bin, :config,  out_summary_forgotten,  out_variable_roles_forgotten,  out_variable_desc_forgotten,  out_indicators_forgotten,  out_profitcurves_forgotten,  out_training_signature_forgotten);
    
    -- store result into table
    insert into  "USER_APL"."MODEL_FORGOTTEN_BIN"select * from :model_forgotten_bin; 
    insert into  "USER_APL"."SUMMARY"            select * from :out_summary;
    insert into  "USER_APL"."VARIABLE_ROLES"     select * from :out_variable_roles;
    insert into  "USER_APL"."VARIABLE_DESC"      select * from :out_variable_desc;
    insert into  "USER_APL"."INDICATORS"         select * from :out_indicators;
    insert into  "USER_APL"."PROFITCURVES"       select * from :out_profitcurves;
    insert into  "USER_APL"."TRAINING_SIGNATURE" select * from :out_training_signature;

    insert into  "USER_APL"."SUMMARY_FORGOTTEN"            select * from :out_summary_forgotten;
    insert into  "USER_APL"."VARIABLE_ROLES_FORGOTTEN"     select * from :out_variable_roles_forgotten;
    insert into  "USER_APL"."VARIABLE_DESC_FORGOTTEN"      select * from :out_variable_desc_forgotten;
    insert into  "USER_APL"."INDICATORS_FORGOTTEN"         select * from :out_indicators_forgotten;
    insert into  "USER_APL"."PROFITCURVES_FORGOTTEN"       select * from :out_profitcurves_forgotten;
    insert into  "USER_APL"."TRAINING_SIGNATURE_FORGOTTEN" select * from :out_training_signature_forgotten;

    select * from "USER_APL"."SUMMARY";
    select * from "USER_APL"."VARIABLE_ROLES";
    select * from "USER_APL"."VARIABLE_DESC";
    select * from "USER_APL"."INDICATORS";
    select * from "USER_APL"."PROFITCURVES";
    select * from "USER_APL"."TRAINING_SIGNATURE";
    select * from "USER_APL"."SUMMARY_FORGOTTEN";
    select * from "USER_APL"."VARIABLE_ROLES_FORGOTTEN";
    select * from "USER_APL"."VARIABLE_DESC_FORGOTTEN";
    select * from "USER_APL"."INDICATORS_FORGOTTEN";
    select * from "USER_APL"."PROFITCURVES_FORGOTTEN";
    select * from "USER_APL"."TRAINING_SIGNATURE_FORGOTTEN";

END;
