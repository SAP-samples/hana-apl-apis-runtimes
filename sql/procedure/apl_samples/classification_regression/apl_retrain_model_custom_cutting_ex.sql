-- ================================================================
-- APL_AREA, RETRAIN_MODEL, using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin-ex.sql).
-- Assumption 3: There's a valid _trained_ model (created by APL) in the MODEL_TRAIN_BIN table.
--               For instance, you have used apl_createmodel_and_train_custom_cutting_ex.sql before
--  @depend(apl_createmodel_and_train_custom_cutting_ex.sql)
connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table TRAINING_CONFIG;
create table TRAINING_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
-- TODO: insert training configuration parameters (to be defined)

drop table MODEL_RETRAINED_BIN;
create table MODEL_RETRAINED_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop view  TEST;
create view  TEST as (select * from APL_SAMPLES.ADULT01);

drop view ESTIMATION;
create view ESTIMATION as (select * from APL_SAMPLES.ADULT01);

drop view  VALIDATION;
create view VALIDATION as (select * from APL_SAMPLES.ADULT01);

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
	model_in  = select * from MODEL_TRAIN_BIN; 
	train_config   = select * from TRAINING_CONFIG;            
    var_role = select * from VARIABLE_ROLES;  
    "SAP_PA_APL"."sap.pa.apl.base::RETRAIN_MODEL_MULTI_DATASET"(:header, :model_in, :train_config, 'USER_APL','ESTIMATION','USER_APL','VALIDATION','USER_APL','TEST', out_train_model, out_train_log, out_sum, out_indic);

    -- store result into table
	insert into  "USER_APL"."MODEL_RETRAINED_BIN"  select * from :out_train_model;
	insert into  "USER_APL"."OPERATION_LOG"        select * from :out_train_log;
    insert into  "USER_APL"."SUMMARY"              select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"           select * from :out_indic;

	-- show result
	select * from "USER_APL"."MODEL_RETRAINED_BIN";
	select * from "USER_APL"."OPERATION_LOG";
	select * from "USER_APL"."SUMMARY";
	select * from "USER_APL"."INDICATORS";
END;
