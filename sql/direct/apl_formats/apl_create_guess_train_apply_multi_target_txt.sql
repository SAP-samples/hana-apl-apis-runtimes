-- ================================================================
-- APL_AREA, call multiple functions for a complete use case
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).
-- ---------------------------------------------------------------------------
-- CREATE_MODEL
-- TRAIN_MODEL
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


-- Ouput table type: dataset
drop type ADULT01_T_OUT;
create type ADULT01_T_OUT as table (
    "KxIndex" INTEGER,
    "age" INTEGER,
    "class" INTEGER,
    "rr_age" INTEGER,    
    "rr_class" DOUBLE    
);


-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------

-- the AFL wrapper generator needs the signature of the expected stored proc
drop table CALL_SIGNATURE;
create table CALL_SIGNATURE like PROCEDURE_SIGNATURE_T;

-- Generate APLWRAPPER_CREATE_MODEL
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','ADULT01_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','MODEL_TXT_OID_T', 'OUT');
insert into CALL_SIGNATURE values (5, 'USER_APL','VARIABLE_DESC_OID_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_CREATE_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','CREATE_MODEL','USER_APL', 'APLWRAPPER_CREATE_MODEL', CALL_SIGNATURE);

-- Generate APLWRAPPER_TRAIN_MODEL
delete from CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_TXT_OID_T',    'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_T',   'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','ADULT01_T',          'IN');
insert into CALL_SIGNATURE values (6, 'USER_APL','MODEL_TXT_OID_T',    'OUT');
insert into CALL_SIGNATURE values (7, 'USER_APL','OPERATION_LOG_T',    'OUT');
insert into CALL_SIGNATURE values (8, 'USER_APL','SUMMARY_T',          'OUT');
insert into CALL_SIGNATURE values (9, 'USER_APL','INDICATORS_T',       'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_TRAIN_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','TRAIN_MODEL','USER_APL', 'APLWRAPPER_TRAIN_MODEL', CALL_SIGNATURE);

-- Generate APLWRAPPER_APPLY_MODEL
delete from CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_TXT_OID_T',    'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','ADULT01_T',          'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','ADULT01_T_OUT',      'OUT');
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
insert into FUNC_HEADER values ('ModelFormat', 'txt');

drop table MODEL_CREATION_CONFIG;
create table MODEL_CREATION_CONFIG like OPERATION_CONFIG_T;
insert into MODEL_CREATION_CONFIG values ('APL/ModelType', 'regression/classification');


drop table TRAIN_CONFIG;
create table TRAIN_CONFIG like OPERATION_CONFIG_T;
-- training configuration is optional, hence the empty table

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_T;
insert into VARIABLE_ROLES values ('age', 'target');
insert into VARIABLE_ROLES values ('class', 'target');

drop table APPLY_CONFIG;
create table APPLY_CONFIG like OPERATION_CONFIG_T;
-- TODO: insert apply configuration parameters (to be defined)


drop table ADULT01_APPLY;
create table ADULT01_APPLY like ADULT01_T_OUT;

drop table TRAIN_LOG;
create table TRAIN_LOG like OPERATION_LOG_T;

drop table APPLY_LOG;
create table APPLY_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

drop table MODEL_CREATE_TXT;
create table MODEL_CREATE_TXT like MODEL_TXT_OID_T;

drop table MODEL_TRAIN_TXT;
create table MODEL_TRAIN_TXT like MODEL_TXT_OID_T;

drop table VARDESC_OUT;
create table VARDESC_OUT like VARIABLE_DESC_OID_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from MODEL_CREATION_CONFIG;  
	train_config   = select * from TRAIN_CONFIG;            
    var_role = select * from VARIABLE_ROLES;  
    dataset  = select * from APL_SAMPLES.ADULT01; 
	apply_config   = select * from APPLY_CONFIG; 
	
    APLWRAPPER_CREATE_MODEL(:header, :config,:dataset,out_model,out_var_desc);
    APLWRAPPER_TRAIN_MODEL(:header, :out_model, :train_config, :var_role, :dataset, out_train_model, out_train_log, out_sum, out_indic);
    APLWRAPPER_APPLY_MODEL(:header, :out_train_model, :apply_config, :dataset, out_apply , out_apply_log);

    -- store result into table
    insert into  "USER_APL"."MODEL_CREATE_TXT" select * from :out_model;
    insert into  "USER_APL"."VARDESC_OUT"      select * from :out_var_desc;
	insert into  "USER_APL"."MODEL_TRAIN_TXT"  select * from :out_train_model;
	insert into  "USER_APL"."TRAIN_LOG"        select * from :out_train_log;
    insert into  "USER_APL"."SUMMARY"          select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"       select * from :out_indic;
	insert into  "USER_APL"."ADULT01_APPLY"    select * from :out_apply;
    insert into  "USER_APL"."APPLY_LOG"        select * from :out_apply_log;

	-- show result
	select * from "USER_APL"."MODEL_CREATE_TXT";
	select * from "USER_APL"."MODEL_TRAIN_TXT";
	select * from "USER_APL"."TRAIN_LOG";

	select * from "USER_APL"."VARDESC_OUT";
	select * from "USER_APL"."SUMMARY";
	select * from "USER_APL"."INDICATORS";
	select * from "USER_APL"."APPLY_LOG";
	select * from "USER_APL"."ADULT01_APPLY";
END;
