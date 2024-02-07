-- ================================================================
-- APL_AREA, call multiple functions for a complete use case
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).
--  @depend(apl_apply_model.sql)

-- ---------------------------------------------------------------------------
-- CREATE_MODEL with guess variable
-- TRAIN_MODEL
-- APPLY_MODEL
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

-- Input table type: dataset
-- Input table type: dataset
drop type ADULT01_T_OUT;
create type ADULT01_T_OUT as table (
    "KxIndex" INTEGER,
    "class" INTEGER,
    "rr_class" DOUBLE
);


-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
drop table CALL_SIGNATURE;
create table CALL_SIGNATURE like PROCEDURE_SIGNATURE_T;

-- Generate APLWRAPPER_CREATE_MODEL
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','ADULT01_T_OUT', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','MODEL_BIN_OID_T', 'OUT');
insert into CALL_SIGNATURE values (5, 'USER_APL','VARIABLE_DESC_OID_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_CREATE_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','CREATE_MODEL','USER_APL', 'APLWRAPPER_CREATE_MODEL', CALL_SIGNATURE);

-- Generate APLWRAPPER_TRAIN_MODEL
delete from CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T',    'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_T',   'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','ADULT01_T_OUT',          'IN');
insert into CALL_SIGNATURE values (6, 'USER_APL','MODEL_BIN_OID_T',    'OUT');
insert into CALL_SIGNATURE values (7, 'USER_APL','OPERATION_LOG_T',    'OUT');
insert into CALL_SIGNATURE values (8, 'USER_APL','SUMMARY_T',          'OUT');
insert into CALL_SIGNATURE values (9, 'USER_APL','INDICATORS_T',       'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_TRAIN_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','TRAIN_MODEL','USER_APL', 'APLWRAPPER_TRAIN_MODEL', CALL_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table CREATE_CONFIG;
create table CREATE_CONFIG like OPERATION_CONFIG_T;
insert into CREATE_CONFIG values ('APL/ModelType', 'statbuilder');

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
-- let this table empty to use guess variables

drop table TRAIN_CONFIG;
create table TRAIN_CONFIG like OPERATION_CONFIG_T;
-- training configuration is optional, hence the empty table

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_T;
insert into VARIABLE_ROLES values ('class', 'target');

drop table TRAIN_LOG;
create table TRAIN_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

drop table MODEL_CREATE_BIN;
create table MODEL_CREATE_BIN like MODEL_BIN_OID_T;

drop table MODEL_PERF_BIN;
create table MODEL_PERF_BIN like MODEL_BIN_OID_T;

drop table VARDESC_OUT;
create table VARDESC_OUT like VARIABLE_DESC_OID_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header         = select * from FUNC_HEADER;             
    config         = select * from CREATE_CONFIG;  
    dataset        = select * from USER_APL.ADULT01_APPLY; 
    
	train_config   = select * from TRAIN_CONFIG;            
    var_role      = select * from VARIABLE_ROLES;  
	
    APLWRAPPER_CREATE_MODEL(:header, :config,:dataset,out_model,out_var_desc);
    APLWRAPPER_TRAIN_MODEL(:header, :out_model, :train_config, :var_role, :dataset, out_train_model, out_train_log, out_sum, out_indic);

    -- store result into table
    insert into  "USER_APL"."MODEL_CREATE_BIN" select * from :out_model;
    insert into  "USER_APL"."VARDESC_OUT"      select * from :out_var_desc;
	insert into  "USER_APL"."MODEL_PERF_BIN"   select * from :out_train_model;
	insert into  "USER_APL"."TRAIN_LOG"        select * from :out_train_log;
    insert into  "USER_APL"."SUMMARY"          select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"       select * from :out_indic;

	-- show result
    select * from "USER_APL"."MODEL_CREATE_BIN";
    select * from "USER_APL"."MODEL_PERF_BIN";
    select * from "USER_APL"."TRAIN_LOG";

    select * from "USER_APL"."VARDESC_OUT";
    select * from "USER_APL"."SUMMARY";
    select * from "USER_APL"."INDICATORS";
END;
