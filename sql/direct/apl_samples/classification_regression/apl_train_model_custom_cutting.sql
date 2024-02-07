-- ================================================================
-- APL_AREA, TRAIN_MODEL, using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid model (created by APL) in the MODEL_BIN table.
--               For instance, you have used apl_createmodel_custom_cutting.sql before
--  @depend(apl_createmodel_custom_cutting.sql)


-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;


-- Input table type: dataset
drop type ADULT01_T;
create type ADULT01_T as table (
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
drop table TRAIN_MODEL_SIGNATURE;
create table TRAIN_MODEL_SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into TRAIN_MODEL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into TRAIN_MODEL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into TRAIN_MODEL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into TRAIN_MODEL_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_T', 'IN');
insert into TRAIN_MODEL_SIGNATURE values (5, 'USER_APL','ADULT01_T', 'IN');
insert into TRAIN_MODEL_SIGNATURE values (6, 'USER_APL','ADULT01_T', 'IN');
insert into TRAIN_MODEL_SIGNATURE values (7, 'USER_APL','ADULT01_T', 'IN');
insert into TRAIN_MODEL_SIGNATURE values (8, 'USER_APL','MODEL_BIN_OID_T', 'OUT');
insert into TRAIN_MODEL_SIGNATURE values (9, 'USER_APL','OPERATION_LOG_T', 'OUT');
insert into TRAIN_MODEL_SIGNATURE values (10, 'USER_APL','SUMMARY_T', 'OUT');
insert into TRAIN_MODEL_SIGNATURE values (11, 'USER_APL','INDICATORS_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_TRAIN_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','TRAIN_MODEL','USER_APL', 'APLWRAPPER_TRAIN_MODEL', TRAIN_MODEL_SIGNATURE);



-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');


drop table TRAINING_CONFIG;
create table TRAINING_CONFIG like OPERATION_CONFIG_T;
-- training configuration is optional, hence the empty table


drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_T;
-- variable roles are optional, hence the empty table

drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like MODEL_BIN_OID_T;

drop table OPERATION_LOG;
create table OPERATION_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

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
	estimation  = select * from ESTIMATION;  
	validation  = select * from VALIDATION;  
	test  = select * from TEST;  
	
    APLWRAPPER_TRAIN_MODEL(:header, :model_in, :train_config, :var_role, :estimation,:validation,:test, out_train_model, out_train_log, out_sum, out_indic);

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
