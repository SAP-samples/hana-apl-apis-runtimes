-- ================================================================
-- APL_AREA, CREATE_MODEL_AND_TRAIN, using a binary format for the model
-- This script creates a model, guesses its description and trains it
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

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
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table CREATE_AND_TRAIN_CONFIG;
create table CREATE_AND_TRAIN_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into CREATE_AND_TRAIN_CONFIG values ('APL/ModelType', 'regression/classification',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/VariableAutoSelection', 'true',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/VariableSelectionBestIteration', 'true',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/VariableSelectionMaxNbOfFinalVariables', '5',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/VariableSelectionMinNbOfFinalVariables', '1',null);


drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- let this table empty to use guess variables

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
-- variable roles are optional, hence the empty table

drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from CREATE_AND_TRAIN_CONFIG;            
    var_desc = select * from VARIABLE_DESC;              
    var_role = select * from VARIABLE_ROLES;  
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role, 'APL_SAMPLES','ADULT01', model,  train_log, train_sum, train_indic);          
    insert into  "USER_APL"."MODEL_TRAIN_BIN" select * from :model;
    insert into  "USER_APL"."OPERATION_LOG"   select * from :train_log;
    insert into  "USER_APL"."SUMMARY"         select * from :train_sum;
    insert into  "USER_APL"."INDICATORS"      select * from :train_indic;

    select * from "USER_APL"."MODEL_TRAIN_BIN";
    select * from "USER_APL"."OPERATION_LOG";
    select * from "USER_APL"."SUMMARY";
    select * from "USER_APL"."INDICATORS";
END;
