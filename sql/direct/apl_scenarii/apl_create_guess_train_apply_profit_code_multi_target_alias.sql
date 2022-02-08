-- ================================================================
-- APL_AREA, call multiple functions for a complete use case
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).
-- ---------------------------------------------------------------------------
-- CREATE_MODEL with guess variable
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
drop table CALL_SIGNATURE;
create column table CALL_SIGNATURE like PROCEDURE_SIGNATURE_T;

-- Generate APLWRAPPER_CREATE_MODEL
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','ADULT01_T', 'IN');
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
insert into CALL_SIGNATURE values (5, 'USER_APL','ADULT01_T',          'IN');
insert into CALL_SIGNATURE values (6, 'USER_APL','MODEL_BIN_OID_T',    'OUT');
insert into CALL_SIGNATURE values (7, 'USER_APL','OPERATION_LOG_T',    'OUT');
insert into CALL_SIGNATURE values (8, 'USER_APL','SUMMARY_T',          'OUT');
insert into CALL_SIGNATURE values (9, 'USER_APL','INDICATORS_T',       'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_TRAIN_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','TRAIN_MODEL','USER_APL', 'APLWRAPPER_TRAIN_MODEL', CALL_SIGNATURE);

-- Generate APLWRAPPER_GET_TABLE_TYPE_FOR_APPLY
delete from CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T',     'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','ADULT01_T',          'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','TABLE_TYPE_T',     'OUT');
insert into CALL_SIGNATURE values (6, 'USER_APL','OPERATION_LOG_T',    'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_GET_TABLE_TYPE_FOR_APPLY');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA', 'GET_TABLE_TYPE_FOR_APPLY', 'USER_APL', 'APLWRAPPER_GET_TABLE_TYPE_FOR_APPLY', CALL_SIGNATURE);

-- Generate APLWRAPPER_APPLY_MODEL
delete from CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T',    'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','ADULT01_T',          'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','ADULT01_T_OUT',      'OUT');
insert into CALL_SIGNATURE values (6, 'USER_APL','OPERATION_LOG_T',    'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_APPLY_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','APPLY_MODEL','USER_APL', 'APLWRAPPER_APPLY_MODEL', CALL_SIGNATURE);

-- Generate APLWRAPPER_EXPORT_PROFITCURVES
delete from CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','PROFITCURVE_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_EXPORT_PROFITCURVES');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','EXPORT_PROFITCURVES','USER_APL', 'APLWRAPPER_EXPORT_PROFITCURVES', CALL_SIGNATURE);

-- Generate APLWRAPPER_EXPORT_APPLY_CODE
delete from CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','RESULT_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_EXPORT_APPLY_CODE');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','EXPORT_APPLY_CODE','USER_APL', 'APLWRAPPER_EXPORT_APPLY_CODE', CALL_SIGNATURE);




-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table CREATE_CONFIG;
create table CREATE_CONFIG like OPERATION_CONFIG_T;
insert into CREATE_CONFIG values ('APL/ModelType', 'regression/classification');

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
-- let this table empty to use guess variables

drop table TRAIN_CONFIG;
create table TRAIN_CONFIG like OPERATION_CONFIG_T;
-- training configuration is optional, hence the empty table

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_T;
insert into VARIABLE_ROLES values ('age', 'target');
insert into VARIABLE_ROLES values ('class', 'target');

drop table GET_APPLY_CONFIG;
create table GET_APPLY_CONFIG like OPERATION_CONFIG_T;
-- TODO: insert apply configuration parameters (to be defined)

drop table APPLY_CONFIG;
create table APPLY_CONFIG like OPERATION_CONFIG_T;
-- TODO: insert apply configuration parameters (to be defined)

drop table EXPORT_PROFIT_CONFIG;
create table EXPORT_PROFIT_CONFIG like OPERATION_CONFIG_T;
-- TODO: insert apply configuration parameters (to be defined)

drop table EXPORT_CODE_CONFIG_1;
create table EXPORT_CODE_CONFIG_1 like OPERATION_CONFIG_T;
insert into EXPORT_CODE_CONFIG_1 values ('APL/CodeType', 'HANA');
insert into EXPORT_CODE_CONFIG_1 values ('APL/CodeTarget', 'class');
insert into EXPORT_CODE_CONFIG_1 values ('APL/CodeKey', '"id"');
insert into EXPORT_CODE_CONFIG_1 values ('APL/CodeSpace', 'APL_SAMPLES.ADULT01');
insert into EXPORT_CODE_CONFIG_1 values ('APL/ApplyExtraMode', 'Min Extra');
insert into EXPORT_CODE_CONFIG_1 values ('APL/CodeUseVarNameAlias', 'true');

drop table EXPORT_CODE_CONFIG_2;
create table EXPORT_CODE_CONFIG_2 like OPERATION_CONFIG_T;
insert into EXPORT_CODE_CONFIG_2 values ('APL/CodeType', 'HANA');
insert into EXPORT_CODE_CONFIG_2 values ('APL/CodeTarget', 'age');
insert into EXPORT_CODE_CONFIG_2 values ('APL/CodeKey', '"id"');
insert into EXPORT_CODE_CONFIG_2 values ('APL/CodeSpace', 'APL_SAMPLES.ADULT01');
insert into EXPORT_CODE_CONFIG_2 values ('APL/ApplyExtraMode', 'No Extra');
insert into EXPORT_CODE_CONFIG_2 values ('APL/CodeUseVarNameAlias', 'true');

drop table EXPORT_CODE_CONFIG_3;
create table EXPORT_CODE_CONFIG_3 like OPERATION_CONFIG_T;
insert into EXPORT_CODE_CONFIG_3 values ('APL/CodeType', 'HANA');
insert into EXPORT_CODE_CONFIG_3 values ('APL/CodeTarget', 'class');
insert into EXPORT_CODE_CONFIG_3 values ('APL/CodeKey', '"id"');
insert into EXPORT_CODE_CONFIG_3 values ('APL/CodeSpace', 'APL_SAMPLES.ADULT01');
insert into EXPORT_CODE_CONFIG_3 values ('APL/ApplyExtraMode', 'Min Extra');
insert into EXPORT_CODE_CONFIG_3 values ('APL/CodeUseVarNameAlias', 'false');

drop table EXPORT_CODE_CONFIG_4;
create table EXPORT_CODE_CONFIG_4 like OPERATION_CONFIG_T;
insert into EXPORT_CODE_CONFIG_4 values ('APL/CodeType', 'HANA');
insert into EXPORT_CODE_CONFIG_4 values ('APL/CodeTarget', 'age');
insert into EXPORT_CODE_CONFIG_4 values ('APL/CodeKey', '"id"');
insert into EXPORT_CODE_CONFIG_4 values ('APL/CodeSpace', 'APL_SAMPLES.ADULT01');
insert into EXPORT_CODE_CONFIG_4 values ('APL/ApplyExtraMode', 'No Extra');
insert into EXPORT_CODE_CONFIG_4 values ('APL/CodeUseVarNameAlias', 'false');

drop table ADULT01_APPLY;
create column table ADULT01_APPLY like ADULT01_T_OUT;

drop table TRAIN_LOG;
create table TRAIN_LOG like OPERATION_LOG_T;

drop table APPLY_LOG;
create table APPLY_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

drop table MODEL_CREATE_BIN;
create table MODEL_CREATE_BIN like MODEL_BIN_OID_T;

drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like MODEL_BIN_OID_T;

drop table VARDESC_OUT;
create table VARDESC_OUT like VARIABLE_DESC_OID_T;

drop table PROFITCURVES_OUT;
create table PROFITCURVES_OUT like PROFITCURVE_T;

drop table EXPORT_CODE_OUT;
create table EXPORT_CODE_OUT like RESULT_T;

drop table GET_APPLY_OUT;
create table GET_APPLY_OUT like TABLE_TYPE_T;

drop table GET_APPLY_OUT_LOG;
create table GET_APPLY_OUT_LOG like OPERATION_LOG_T;

drop table INPUT_DATA;
create table INPUT_DATA like ADULT01_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header         = select * from FUNC_HEADER;             
    config         = select * from CREATE_CONFIG;  
	train_config   = select * from TRAIN_CONFIG;            
    var_role       = select * from VARIABLE_ROLES;  
    dataset        = select * from APL_SAMPLES.ADULT01; 
    apply_in       = select * from INPUT_DATA; 
    get_config     = select * from GET_APPLY_CONFIG;
	apply_config   = select * from APPLY_CONFIG; 
    curves_config  = select * from EXPORT_PROFIT_CONFIG; 
    export_1_config  = select * from EXPORT_CODE_CONFIG_1; 
    export_2_config  = select * from EXPORT_CODE_CONFIG_2; 
    export_3_config  = select * from EXPORT_CODE_CONFIG_3; 
    export_4_config  = select * from EXPORT_CODE_CONFIG_4; 

    APLWRAPPER_CREATE_MODEL(:header, :config,:dataset,out_model,out_var_desc);
    APLWRAPPER_TRAIN_MODEL(:header, :out_model, :train_config, :var_role, :dataset, out_train_model, out_train_log, out_sum, out_indic);
    APLWRAPPER_GET_TABLE_TYPE_FOR_APPLY(:header, :out_train_model, :get_config, :apply_in, :out_get_type, :out_get_log);
    APLWRAPPER_APPLY_MODEL(:header, :out_train_model, :apply_config, :dataset, out_apply , out_apply_log);
    APLWRAPPER_EXPORT_PROFITCURVES(:header, :out_train_model, :curves_config, out_curves);
    APLWRAPPER_EXPORT_APPLY_CODE(:header, :out_train_model, :export_1_config, out_code);
    insert into  "USER_APL"."EXPORT_CODE_OUT"  select * from :out_code;
    APLWRAPPER_EXPORT_APPLY_CODE(:header, :out_train_model, :export_2_config, out_code);
    insert into  "USER_APL"."EXPORT_CODE_OUT"  select * from :out_code;
    APLWRAPPER_EXPORT_APPLY_CODE(:header, :out_train_model, :export_3_config, out_code);
    insert into  "USER_APL"."EXPORT_CODE_OUT"  select * from :out_code;
    APLWRAPPER_EXPORT_APPLY_CODE(:header, :out_train_model, :export_4_config, out_code);
    insert into  "USER_APL"."EXPORT_CODE_OUT"  select * from :out_code;

    -- store result into table
    insert into  "USER_APL"."MODEL_CREATE_BIN" select * from :out_model;
    insert into  "USER_APL"."VARDESC_OUT"      select * from :out_var_desc;
	insert into  "USER_APL"."MODEL_TRAIN_BIN"  select * from :out_train_model;
	insert into  "USER_APL"."TRAIN_LOG"        select * from :out_train_log;
    insert into  "USER_APL"."SUMMARY"          select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"       select * from :out_indic;

    insert into  "USER_APL"."GET_APPLY_OUT"     select * from :out_get_type;
    insert into  "USER_APL"."GET_APPLY_OUT_LOG" select * from :out_get_log;

	insert into  "USER_APL"."ADULT01_APPLY"     select * from :out_apply;
    insert into  "USER_APL"."APPLY_LOG"        select * from :out_apply_log;

    insert into  "USER_APL"."PROFITCURVES_OUT" select * from :out_curves;

	-- show result
    select * from "USER_APL"."MODEL_CREATE_BIN";
    select * from "USER_APL"."MODEL_TRAIN_BIN";
    select * from "USER_APL"."TRAIN_LOG";
    select * from "USER_APL"."VARDESC_OUT";
    select * from "USER_APL"."SUMMARY";
    select * from "USER_APL"."INDICATORS";
    select * from "USER_APL"."APPLY_LOG";
    select * from "USER_APL"."ADULT01_APPLY";
    select * from "USER_APL"."PROFITCURVES_OUT";
    select * from "USER_APL"."EXPORT_CODE_OUT";
    select * from "USER_APL"."GET_APPLY_OUT_LOG";
    select * from "USER_APL"."GET_APPLY_OUT";
END;
