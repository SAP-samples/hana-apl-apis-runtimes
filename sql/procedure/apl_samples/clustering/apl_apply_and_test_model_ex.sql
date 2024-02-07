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
insert into CREATE_AND_TRAIN_CONFIG values ('APL/ModelType', 'clustering',null);

drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- let this table empty to use guess variables

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
insert into VARIABLE_ROLES values ('class', 'skip',null,null,null);
insert into VARIABLE_ROLES values ('fnlwgt', 'target',null,null,null);

drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
-- TODO: insert training configuration parameters (to be defined)

drop table APPLY_TEST_LOG;
create table APPLY_TEST_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table APPLY_MODEL_AND_TEST_BIN;
create table APPLY_MODEL_AND_TEST_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table APPLY_TEST_INDICATORS;
create table APPLY_TEST_INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table ADULT01_APPLY_TEST;
-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    config       = select * from CREATE_AND_TRAIN_CONFIG;            
    var_desc     = select * from VARIABLE_DESC;              
    var_role     = select * from VARIABLE_ROLES;  
    header       = select * from FUNC_HEADER;             
    apply_config = select * from APPLY_CONFIG; 	           

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role, 'APL_SAMPLES','ADULT01',out_model,out_log,out_sum,out_indic);    
    -- store result into table
    insert into  "USER_APL"."MODEL_TRAIN_BIN" select * from :out_model;
    insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;
    insert into  "USER_APL"."SUMMARY"         select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"      select * from :out_indic;

    "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header, :out_model, :apply_config, 'APL_SAMPLES','ADULT01', out_apply_type, out_apply_test_log);
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_TABLE_FROM_TABLE_TYPE"('USER_APL', 'ADULT01_APPLY_TEST', :out_apply_type );
    "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL_AND_TEST"(:header, :out_model, :apply_config,  'APL_SAMPLES','ADULT01', 'USER_APL','ADULT01_APPLY_TEST', model_test,out_apply_log, out_indic);

    -- store result into table
	insert into  "USER_APL"."APPLY_MODEL_AND_TEST_BIN"  select * from :model_test;
	insert into  "USER_APL"."APPLY_TEST_LOG"            select * from :out_apply_log;
	insert into  "USER_APL"."APPLY_TEST_INDICATORS"     select * from :out_indic;

	-- show result
	select * from "USER_APL"."APPLY_MODEL_AND_TEST_BIN";
	select * from "USER_APL"."APPLY_TEST_LOG";
	select * from "USER_APL"."APPLY_TEST_INDICATORS";
END;
