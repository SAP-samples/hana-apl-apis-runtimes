-- ================================================================
-- APL_AREA, call multiple functions for a complete use case
--
-- ---------------------------------------------------------------------------
-- copy a table in another ( use to bench data access layer of kxen and afl with a simple copy of a table into another
--- without any statistic computation ) 
-- CREATE_MODEL_AND_TRAIN statBuilder
-- APPLY_MODEL  
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

drop type ADULT01_OUT_T;
create type ADULT01_OUT_T as table (
	"KxIndex" BigInt,
	"age" BigInt,
	"workclass" NVARCHAR(32),
	"fnlwgt" BigInt,
	"education" NVARCHAR(32),
	"education-num" BigInt,
	"marital-status" NVARCHAR(32),
	"occupation" NVARCHAR(32),
	"relationship" NVARCHAR(32),
	"race" NVARCHAR(32),
	"sex" NVARCHAR(16),
	"capital-gain" BigInt,
	"capital-loss" BigInt,
	"hours-per-week" BigInt,
	"native-country" NVARCHAR(32),
	"class" BigInt
);

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
drop table CALL_SIGNATURE;
create table CALL_SIGNATURE like PROCEDURE_SIGNATURE_T;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_T', 'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','ADULT01_T', 'IN');
insert into CALL_SIGNATURE values (6, 'USER_APL','MODEL_BIN_OID_T', 'OUT');
insert into CALL_SIGNATURE values (7, 'USER_APL','OPERATION_LOG_T', 'OUT');
insert into CALL_SIGNATURE values (8, 'USER_APL','SUMMARY_T', 'OUT');
insert into CALL_SIGNATURE values (9, 'USER_APL','INDICATORS_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_CREATE_MODEL_AND_TRAIN');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','CREATE_MODEL_AND_TRAIN','USER_APL', 'APLWRAPPER_CREATE_MODEL_AND_TRAIN', CALL_SIGNATURE);

-- Generate APLWRAPPER_APPLY_MODEL
delete from CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T',    'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','ADULT01_T',          'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','ADULT01_OUT_T',      'OUT');
insert into CALL_SIGNATURE values (6, 'USER_APL','OPERATION_LOG_T',    'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_APPLY_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','APPLY_MODEL','USER_APL', 'APLWRAPPER_APPLY_MODEL', CALL_SIGNATURE);

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
insert into CREATE_AND_TRAIN_CONFIG values ('APL/ModelType', 'statbuilder');
insert into CREATE_AND_TRAIN_CONFIG values ('Protocols/Default/Transforms/Kxen.StatBuilder/Parameters/ComputeStatistics', 'false');

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
-- let this table empty to use guess variables

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

drop table APPLY_CONFIG;
create table APPLY_CONFIG like OPERATION_CONFIG_T;
-- TODO: insert apply configuration parameters (to be defined)

drop table ADULT01_APPLY;
create table ADULT01_APPLY like ADULT01_OUT_T;

drop table APPLY_LOG;
create table APPLY_LOG like OPERATION_LOG_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from CREATE_AND_TRAIN_CONFIG; 
    var_desc = select * from VARIABLE_DESC;              
    var_role = select * from VARIABLE_ROLES;  
    dataset  = select * from APL_SAMPLES.ADULT01;  
    apply_config = select * from APPLY_CONFIG; 	           

    APLWRAPPER_CREATE_MODEL_AND_TRAIN(:header, :config, :var_desc,:var_role, :dataset,out_model,out_log,out_sum,out_indic);
    APLWRAPPER_APPLY_MODEL(:header, :out_model, :apply_config,  :dataset, out_apply , out_apply_log);

    -- store result into table
    insert into  "USER_APL"."MODEL_TRAIN_BIN" select * from :out_model;
    insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;
    insert into  "USER_APL"."SUMMARY"         select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"      select * from :out_indic;
    insert into  "USER_APL"."ADULT01_APPLY"   select * from :out_apply;
	insert into  "USER_APL"."APPLY_LOG"       select * from :out_apply_log;

	-- show result
	select * from :out_apply;
	select * from :out_apply_log;
END;

