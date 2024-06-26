-- ================================================================
-- APL_AREA, CREATE_MODEL_AND_TRAIN, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).


-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

-- Input table type: dataset
drop type CENSUS_T;
create type CENSUS_T as table (
    "id" INTEGER,
	"age" INTEGER,
	"workclass" NVARCHAR(32),
	"fnlwgt" INTEGER,
	"education" NVARCHAR(32),
	"education-num" INTEGER,
	"marital-status" NVARCHAR(32),
	"occupation" NVARCHAR(32),
	"relationship" NVARCHAR(32),
	"race" NVARCHAR(32),
	"sex" NVARCHAR(16),
	"capital-gain" INTEGER,
	"capital-loss" INTEGER,
	"hours-per-week" INTEGER,
	"native-country" NVARCHAR(32),
	"class" INTEGER
);

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
-- the AFL wrapper generator needs the signature of the expected stored proc
drop table CREATE_MODEL_AND_TRAIN_SIGNATURE;
create table CREATE_MODEL_AND_TRAIN_SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_T', 'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_T', 'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (5, 'USER_APL','CENSUS_T', 'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (6, 'USER_APL','MODEL_BIN_OID_T', 'OUT');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (7, 'USER_APL','OPERATION_LOG_T', 'OUT');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (8, 'USER_APL','SUMMARY_T', 'OUT');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (9, 'USER_APL','INDICATORS_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_CREATE_MODEL_AND_TRAIN');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','CREATE_MODEL_AND_TRAIN','USER_APL', 'APLWRAPPER_CREATE_MODEL_AND_TRAIN', CREATE_MODEL_AND_TRAIN_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table CREATE_AND_TRAIN_CONFIG;
create table CREATE_AND_TRAIN_CONFIG like OPERATION_CONFIG_T;
insert into CREATE_AND_TRAIN_CONFIG values ('APL/ModelType', 'regression/classification');

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
insert into VARIABLE_DESC values (0, 'id', 'integer', 'continuous', 1, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (1, 'age', 'integer', 'continuous', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (2, 'workclass', 'string', 'nominal', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (3, 'fnlwgt', 'integer', 'continuous', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (4, 'education', 'string', 'nominal', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (5, 'education-num', 'integer', 'nominal', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (6, 'marital-status', 'string', 'nominal', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (7, 'occupation', 'string', 'nominal', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (8, 'relationship', 'string', 'nominal', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (9, 'race', 'string', 'nominal', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (10, 'sex', 'string', 'nominal', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (11, 'capital-gain', 'integer', 'nominal', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (12, 'capital-loss', 'integer', 'nominal', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (13, 'hours-per-week', 'integer', 'nominal', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (14, 'native-country', 'string', 'nominal', 0, 0, NULL, NULL, '');
insert into VARIABLE_DESC values (15, 'class', 'integer', 'nominal', 0, 0, NULL, NULL, '');

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_T;
insert into VARIABLE_ROLES values ('class', 'target');

drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like MODEL_BIN_OID_T;

drop table OPERATION_LOG;
create table OPERATION_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from CREATE_AND_TRAIN_CONFIG;            
    var_desc = select * from VARIABLE_DESC;              
    var_role = select * from VARIABLE_ROLES;  
    dataset  = select * from APL_SAMPLES.CENSUS;  

    APLWRAPPER_CREATE_MODEL_AND_TRAIN(:header, :config, :var_desc,:var_role, :dataset, out_model,  out_log, out_sum, out_indic);          
    insert into  "USER_APL"."MODEL_TRAIN_BIN" select * from :out_model;
    insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;
    insert into  "USER_APL"."SUMMARY"         select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"      select * from :out_indic;

	-- show result
    select * from "USER_APL"."MODEL_TRAIN_BIN";
    select * from "USER_APL"."OPERATION_LOG";
    select * from "USER_APL"."SUMMARY";
    select * from "USER_APL"."INDICATORS";
END;
