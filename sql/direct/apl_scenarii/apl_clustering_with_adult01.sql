-- ================================================================
-- APL_AREA, call multiple functions for a complete use case
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).
-- ---------------------------------------------------------------------------
-- CREATE_MODEL_AND_TRAIN
-- GET_TABLE_TYPE_FOR_APPLY
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

-- --------------------------------------------------------------------------
-- Set 'class' as the target. The key 'id' is going to be automatically skipped
-- --------------------------------------------------------------------------
drop table ADULT01_ROLES;
create table ADULT01_ROLES like VARIABLE_ROLES_T;
insert into ADULT01_ROLES values ('class', 'skip');
insert into ADULT01_ROLES values ('fnlwgt', 'target');


-- --------------------------------------------------------------------------
-- Create table type for apply 
-- This table type can actually be guessed using GET_TABLE_TYPE_FOR_APPLY
-- --------------------------------------------------------------------------
drop type ADULT01_APPLYOUT_T;
create type ADULT01_APPLYOUT_T as table (
    "KxIndex" INTEGER,
    "fnlwgt" INTEGER,
    "kc_fnlwgt" INTEGER    
);


-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------

-- Generate APLWRAPPER_CREATE_MODEL_AND_TRAIN
drop table CALL_SIGNATURE;
create column table CALL_SIGNATURE like PROCEDURE_SIGNATURE_T;
insert into CALL_SIGNATURE values (1,'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CALL_SIGNATURE values (2,'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (3,'USER_APL','VARIABLE_DESC_T', 'IN');
insert into CALL_SIGNATURE values (4,'USER_APL','VARIABLE_ROLES_T', 'IN');
insert into CALL_SIGNATURE values (5,'USER_APL','ADULT01_T', 'IN');
insert into CALL_SIGNATURE values (6,'USER_APL','MODEL_BIN_OID_T', 'OUT');
insert into CALL_SIGNATURE values (7,'USER_APL','OPERATION_LOG_T', 'OUT');
insert into CALL_SIGNATURE values (8,'USER_APL','SUMMARY_T', 'OUT');
insert into CALL_SIGNATURE values (9,'USER_APL','INDICATORS_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_CREATE_MODEL_AND_TRAIN');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','CREATE_MODEL_AND_TRAIN','USER_APL', 'APLWRAPPER_CREATE_MODEL_AND_TRAIN', CALL_SIGNATURE);


-- Generate APLWRAPPER_GET_TABLE_TYPE_FOR_APPLY
delete from CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T',    'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','ADULT01_T',           'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','TABLE_TYPE_T',       'OUT');
insert into CALL_SIGNATURE values (6, 'USER_APL','OPERATION_LOG_T',    'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_GET_TABLE_TYPE_FOR_APPLY');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA', 'GET_TABLE_TYPE_FOR_APPLY', 'USER_APL', 'APLWRAPPER_GET_TABLE_TYPE_FOR_APPLY', CALL_SIGNATURE);

-- Generate APLWRAPPER_APPLY_MODEL
delete from CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T',    'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','ADULT01_T',          'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','ADULT01_APPLYOUT_T', 'OUT');
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

drop table MODEL_CONFIG;
create table MODEL_CONFIG like OPERATION_CONFIG_T;
insert into MODEL_CONFIG values ('APL/ModelType', 'clustering');
insert into MODEL_CONFIG values ('APL/CuttingStrategy', 'random with no test');

drop table APPLY_CONFIG;
create table APPLY_CONFIG like OPERATION_CONFIG_T;

drop table ADULT01_DESC;
drop table ADULT01_APPLY;
drop table SUMMARY;
drop table INDICATORS;
drop table MODEL_TRAIN_BIN;
drop table TABLE_TYPE;
drop table OPERATION_LOG;
drop table INPUT_DATA;

create table ADULT01_DESC like VARIABLE_DESC_T;
create table ADULT01_APPLY like ADULT01_APPLYOUT_T;
create table SUMMARY like SUMMARY_T;
create table INDICATORS like INDICATORS_T;
create table MODEL_TRAIN_BIN like MODEL_BIN_OID_T;
create table TABLE_TYPE like TABLE_TYPE_T;
create table OPERATION_LOG like OPERATION_LOG_T;
create table INPUT_DATA like ADULT01_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from MODEL_CONFIG;            
    var_desc = select * from ADULT01_DESC;              
    var_role = select * from ADULT01_ROLES;  
    dataset  = select * from APL_SAMPLES.ADULT01;  
	apply_config   = select * from APPLY_CONFIG;       
	apply_in      = select * from INPUT_DATA;       

    APLWRAPPER_CREATE_MODEL_AND_TRAIN(:header, :config, :var_desc,:var_role, :dataset,out_model,out_log,out_sum,out_indic);
    insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;

	APLWRAPPER_GET_TABLE_TYPE_FOR_APPLY(:header, :out_model, :apply_config, :apply_in, :out_table_type, out_log);
	insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;

    APLWRAPPER_APPLY_MODEL(:header, :out_model, :apply_config, :dataset, out_apply , out_log);
     insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;

    -- store result into table
    insert into  "USER_APL"."MODEL_TRAIN_BIN" select * from :out_model;
    insert into  "USER_APL"."SUMMARY"         select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"      select * from :out_indic;
	insert into  "USER_APL"."ADULT01_APPLY"    select * from :out_apply;
	insert into  "USER_APL"."TABLE_TYPE"      select * from :out_table_type;

	-- show result
	select * from :out_model;
	select * from :out_log;
	select * from :out_sum;
	select * from :out_indic;
	select * from :out_table_type;
	select * from :out_apply;
END;


