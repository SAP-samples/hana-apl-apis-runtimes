-- @required(hanaMinimumVersion,2.0.30)
-- @required(hanaMaximumVersion,2.99.999)
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

-- Create a view which contains the sorted dataset
drop view ADULT01_ANY;
create view ADULT01_ANY as ( select 
	to_integer("age") as "age",
	"workclass",
	to_integer("fnlwgt") as "fnlwgt",
	"education",
	to_integer("education-num") as "education-num",
	"marital-status",
	"occupation",
	"relationship",
	"race",
	"sex",
	to_integer("capital-gain") as "capital-gain",
	to_integer("capital-loss") as "capital-loss",
	to_integer("hours-per-week") as "hours-per-week",
	"native-country",
	to_integer("class") as "class"
from "APL_SAMPLES"."ADULT01" );

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
call "_SYS_AFL"."APL_CREATE_MODEL_AND_TRAIN"(FUNC_HEADER, CREATE_AND_TRAIN_CONFIG, VARIABLE_DESC, VARIABLE_ROLES, "USER_APL"."ADULT01_ANY", MODEL_TRAIN_BIN, OPERATION_LOG, SUMMARY, INDICATORS) with overview;
select * from "USER_APL"."MODEL_TRAIN_BIN";
select * from "USER_APL"."OPERATION_LOG";
select * from "USER_APL"."SUMMARY";
select * from "USER_APL"."INDICATORS";
