-- ================================================================
-- APL_AREA, TRAIN_MODEL, using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid model (created by APL) in the MODEL_BIN table.
--               For instance, you have used apl_createmodel_custom_cutting_ex.sql before
--  @depend(apl_createmodel_custom_cutting_ex.sql)


-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

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


drop table TRAINING_CONFIG;
create table TRAINING_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
-- training configuration is optional, hence the empty table

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
-- variable roles are optional, hence the empty table

drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

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
	model_in  = select * from MODEL_BIN; 
	train_config   = select * from TRAINING_CONFIG;            
    var_role = select * from VARIABLE_ROLES;  
	
    "SAP_PA_APL"."sap.pa.apl.base::TRAIN_MODEL_MULTI_DATASET"(:header, :model_in, :train_config, :var_role, 'USER_APL','ESTIMATION','USER_APL','VALIDATION','USER_APL','TEST', out_train_model, out_train_log, out_sum, out_indic);

    -- store result into table
	insert into  "USER_APL"."MODEL_TRAIN_BIN"  select * from :out_train_model;
	insert into  "USER_APL"."OPERATION_LOG"    select * from :out_train_log;
    insert into  "USER_APL"."SUMMARY"          select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"       select * from :out_indic;

	-- show result
	select * from "USER_APL"."MODEL_TRAIN_BIN";
	select * from "USER_APL"."OPERATION_LOG";
	select * from "USER_APL"."SUMMARY";
	select * from "USER_APL"."INDICATORS";
END;
