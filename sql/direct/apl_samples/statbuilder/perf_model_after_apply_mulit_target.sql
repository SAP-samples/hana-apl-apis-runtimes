-- ================================================================
-- APL_AREA, call multiple functions for a complete use case
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- ---------------------------------------------------------------------------
-- CREATE_MODEL statBuilder to compute comperformance on scrored dataSet  
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


truncate table CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T',     'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','ADULT01_T',          'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','ADULT01_T_OUT',      'OUT');
insert into CALL_SIGNATURE values (6, 'USER_APL','OPERATION_LOG_T',    'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_APPLY_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','APPLY_MODEL','USER_APL', 'APLWRAPPER_APPLY_MODEL', CALL_SIGNATURE);


truncate table CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_T', 'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','ADULT01_T_OUT', 'IN');
insert into CALL_SIGNATURE values (6, 'USER_APL','MODEL_BIN_OID_T', 'OUT');
insert into CALL_SIGNATURE values (7, 'USER_APL','OPERATION_LOG_T', 'OUT');
insert into CALL_SIGNATURE values (8, 'USER_APL','SUMMARY_T', 'OUT');
insert into CALL_SIGNATURE values (9, 'USER_APL','INDICATORS_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_STAT_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','CREATE_MODEL_AND_TRAIN','USER_APL', 'APLWRAPPER_STAT_MODEL', CALL_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');


--- Create Regression/Classification Model -------------------------------------
drop table CREATE_AND_TRAIN_CONFIG;
create table CREATE_AND_TRAIN_CONFIG like OPERATION_CONFIG_T;
insert into CREATE_AND_TRAIN_CONFIG values ('APL/ModelType', 'regression/classification');

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
-- let this table empty to use guess variables
       
drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_T;
insert into VARIABLE_ROLES values ('class', 'target');
insert into VARIABLE_ROLES values ('age',   'target');
select * from VARIABLE_ROLES;

drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like MODEL_BIN_OID_T;

drop table OPERATION_LOG;
create table OPERATION_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

--- apply 
drop table APPLY_CONFIG;
create table APPLY_CONFIG like OPERATION_CONFIG_T;
-- TODO: insert training configuration parameters (to be defined)

drop table ADULT01_APPLY;
create table ADULT01_APPLY like ADULT01_T_OUT;

drop table APPLY_LOG;
create table APPLY_LOG like OPERATION_LOG_T;


--- Create Model StatBuilder -------------------------------------
drop table STAT_CONFIG;
create table STAT_CONFIG like OPERATION_CONFIG_T;
insert into STAT_CONFIG values ('APL/ModelType', 'statbuilder');
insert into STAT_CONFIG values ('APL/VariableEstimatorOf', 'rr_class;class');
insert into STAT_CONFIG values ('APL/VariableEstimatorOf', 'rr_age;age');


drop table STAT_VARIABLE_DESC;
create table STAT_VARIABLE_DESC like VARIABLE_DESC_T;
-- define var description 
insert into STAT_VARIABLE_DESC values(0,'KxIndex','integer','continuous',1,0,'','','');
insert into STAT_VARIABLE_DESC values(1,'age','integer','continuous',0,0,'','','');
insert into STAT_VARIABLE_DESC values(2,'class','integer','nominal',0,0,'','','');
insert into STAT_VARIABLE_DESC values(3,'rr_age','integer','continuous',0,0,'','','');
insert into STAT_VARIABLE_DESC values(4,'rr_class','number','continuous',0,0,'','','');

drop table STAT_VARIABLE_ROLES;
create table STAT_VARIABLE_ROLES like VARIABLE_ROLES_T;
insert into VARIABLE_ROLES values ('class', 'target');
insert into STAT_VARIABLE_ROLES values ('age', 'target');

drop table STAT_MODEL_BIN;
create table STAT_MODEL_BIN like MODEL_BIN_OID_T;

drop table STAT_OPERATION_LOG;
create table STAT_OPERATION_LOG like OPERATION_LOG_T;

drop table STAT_SUMMARY;
create table STAT_SUMMARY like SUMMARY_T;

drop table STAT_INDICATORS;
create table STAT_INDICATORS like INDICATORS_T;

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
    stat_config = select * from STAT_CONFIG; 	   
    stat_var_desc = select * from VARIABLE_DESC;              
    stat_var_role = select * from VARIABLE_ROLES;  

    APLWRAPPER_CREATE_MODEL_AND_TRAIN(:header, :config, :var_desc,:var_role, :dataset,out_model,out_log,out_sum,out_indic);
    APLWRAPPER_APPLY_MODEL(:header, :out_model, :apply_config,  :dataset, out_apply , out_apply_log);
    APLWRAPPER_STAT_MODEL(:header, :stat_config, :stat_var_desc, :stat_var_role, :out_apply, out_stat_model, out_stat_log, out_stat_sum, out_stat_indic);

    -- store result into table
    insert into  "USER_APL"."MODEL_TRAIN_BIN" select * from :out_model;
    insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;
    insert into  "USER_APL"."SUMMARY"         select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"      select * from :out_indic;

    insert into  "USER_APL"."ADULT01_APPLY"   select * from :out_apply;
	insert into  "USER_APL"."APPLY_LOG"       select * from :out_apply_log;

    insert into  "USER_APL"."STAT_MODEL_BIN"     select * from :out_stat_model;
	insert into  "USER_APL"."STAT_OPERATION_LOG" select * from :out_stat_log;
    insert into  "USER_APL"."STAT_SUMMARY"       select * from :out_stat_sum;
    insert into  "USER_APL"."STAT_INDICATORS"    select * from :out_stat_indic;

	-- show result
    select * from :out_indic     where "VARIABLE" = 'rr_age';
    select * from :out_stat_indic where "VARIABLE" = 'rr_class';
END;
