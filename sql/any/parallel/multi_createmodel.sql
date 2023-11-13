-- @required(hanaMinimumVersion,2.0.72)
-- @required(hanaMaximumVersion,2.0.99)
-- ================================================================
-- APL_AREA, CREATE_MODEL_AND_TRAIN, using a binary format for the model
-- This script creates a model, guesses its description and trains it
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

drop view INPUT_DATASET;
create view INPUT_DATASET as (select 
"age",
"workclass",
"fnlwgt",
"education",
"education-num",
"marital-status",
"occupation",
"relationship",
"race",
"sex",
"capital-gain",
"capital-loss",
to_integer("hours-per-week") as "hours-per-week",
"native-country",
to_integer("class") as "class"
 from "APL_SAMPLES"."ADULT01");


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
-- modify input and ouput table by adding a new column "config" to define multi configuration
-- --------------------------------------------------------------------------

drop table MULTI_CONFIG;
create table MULTI_CONFIG as ( select to_integer(1) as "config", * from CREATE_AND_TRAIN_CONFIG );
insert into MULTI_CONFIG values ('1','APL/ModelType', 'regression/classification',null);
insert into MULTI_CONFIG values ('1','APL/VariableAutoSelection', 'false',null);
insert into MULTI_CONFIG values ('1','APL/VariableSelectionBestIteration', 'true',null);
insert into MULTI_CONFIG values ('1','APL/VariableSelectionMaxNbOfFinalVariables', '5',null);
insert into MULTI_CONFIG values ('1','APL/VariableSelectionMinNbOfFinalVariables', '1',null);
insert into MULTI_CONFIG values ('2','APL/ModelType', 'regression/classification',null);
insert into MULTI_CONFIG values ('3','APL/ModelType', 'regression/classification',null);
insert into MULTI_CONFIG values ('4','APL/ModelType', 'regression/classification',null);
insert into MULTI_CONFIG values ('5','APL/ModelType', 'regression/classification',null);
insert into MULTI_CONFIG values ('6','APL/ModelType', 'regression/classification',null);
insert into MULTI_CONFIG values ('7','APL/ModelType', 'regression/classification',null);
insert into MULTI_CONFIG values ('8','APL/ModelType', 'regression/classification',null);


drop table MULTI_MODEL_TRAIN_BIN;
create table MULTI_MODEL_TRAIN_BIN as ( select to_integer(0) as "config", * from MODEL_TRAIN_BIN );

drop table MULTI_OPERATION_LOG;
create table MULTI_OPERATION_LOG as ( select to_integer(0) as "config", * from OPERATION_LOG );

drop table MULTI_SUMMARY;
create table MULTI_SUMMARY as ( select to_integer(0) as "config", * from SUMMARY );

drop table MULTI_INDICATORS;
create table MULTI_INDICATORS as ( select to_integer(0) as "config", * from INDICATORS );

-- --------------------------------------------------------------------------
-- Execute execute a train based foreach config  
-- --------------------------------------------------------------------------
call "_SYS_AFL"."APL_CREATE_MODEL_AND_TRAIN"(FUNC_HEADER, MULTI_CONFIG, VARIABLE_DESC, VARIABLE_ROLES, "INPUT_DATASET", MULTI_MODEL_TRAIN_BIN,MULTI_OPERATION_LOG,MULTI_SUMMARY,MULTI_INDICATORS) with overview WITH HINT(PARALLEL_BY_PARAMETER_VALUES (p2."config"));

select * from "USER_APL"."MULTI_MODEL_TRAIN_BIN";
select * from "USER_APL"."MULTI_OPERATION_LOG";
select * from "USER_APL"."MULTI_SUMMARY";
select * from "USER_APL"."MULTI_INDICATORS";
