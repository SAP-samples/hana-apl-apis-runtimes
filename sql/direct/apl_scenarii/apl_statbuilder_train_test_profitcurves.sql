-- ================================================================
-- APL_AREA, call multiple functions for a complete use case
--
-- ---------------------------------------------------------------------------
-- Test Deviation between 2 dataset  (DATASET_1 ( first 100 row of APL_SAMPLES.ADULT01)  and  DATASET_2 ( next 100 row of APL_SAMPLES.ADULT01 ) )
-- CREATE_MODEL statBuilder
-- TEST_MODEL 
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

drop type PROFITCURVE_TEST_T;
create type PROFITCURVE_TEST_T as table (
    "OID"        VARCHAR(50),
    "TYPE"       VARCHAR(100),
    "VARIABLE"   VARCHAR(100),
    "TARGET"     VARCHAR(100),
    "Label"      VARCHAR(100),
    "Frequency"  VARCHAR(100),
    "Random"     VARCHAR(100),
    "Wizard"     VARCHAR(100),
    "Estimation" VARCHAR(100),
    "Validation" VARCHAR(100),
    "Test"       VARCHAR(100),
    "ApplyIn"    VARCHAR(100)
);

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
drop table CALL_SIGNATURE;
create column table CALL_SIGNATURE like PROCEDURE_SIGNATURE_T;

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

-- Generate APLWRAPPER_TEST_MODEL
delete from CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T',     'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','ADULT01_T',          'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','MODEL_BIN_OID_T',    'OUT');
insert into CALL_SIGNATURE values (6, 'USER_APL','OPERATION_LOG_T',    'OUT');
insert into CALL_SIGNATURE values (7, 'USER_APL','INDICATORS_T',       'OUT');
call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_TEST_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','TEST_MODEL', 'USER_APL', 'APLWRAPPER_TEST_MODEL', CALL_SIGNATURE);


drop table CALL_SIGNATURE;
create column table CALL_SIGNATURE   like PROCEDURE_SIGNATURE_T;

insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','PROFITCURVE_TEST_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_EXPORT_PROFITCURVES');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','EXPORT_PROFITCURVES','USER_APL', 'APLWRAPPER_EXPORT_PROFITCURVES', CALL_SIGNATURE);


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table CREATE_AND_TRAIN_CONFIG;
create table CREATE_AND_TRAIN_CONFIG like OPERATION_CONFIG_T;
insert into CREATE_AND_TRAIN_CONFIG values ('APL/ModelType', 'statbuilder');

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
-- let this table empty to use guess variables

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_T;
insert into VARIABLE_ROLES values ('class', 'target');
-- variable roles are optional, hence the empty table

drop table MODEL_TEST_BIN_1;
create table MODEL_TEST_BIN_1 like MODEL_BIN_OID_T;

drop table MODEL_TEST_BIN_2;
create table MODEL_TEST_BIN_2 like MODEL_BIN_OID_T;

drop table OPERATION_LOG;
create table OPERATION_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

drop table TEST_CONFIG;
create table TEST_CONFIG like OPERATION_CONFIG_T;

drop table TEST_LOG;
create column table TEST_LOG like OPERATION_LOG_T;

drop table TEST_INDICATORS;
create table TEST_INDICATORS like INDICATORS_T;

drop table EXPORT_CONFIG;
create table EXPORT_CONFIG like OPERATION_CONFIG_T;

drop table PROFITCURVES_TRAIN;
create table PROFITCURVES_TRAIN like PROFITCURVE_TEST_T;

drop table PROFITCURVES_TEST;
create table PROFITCURVES_TEST like PROFITCURVE_TEST_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from CREATE_AND_TRAIN_CONFIG;            
    var_desc = select * from VARIABLE_DESC;              
    var_role = select * from VARIABLE_ROLES;  
    dataset_1  = select * from APL_SAMPLES.ADULT01  LIMIT 100;  
    dataset_2     = select * from APL_SAMPLES.ADULT01  LIMIT 100  OFFSET 100;  
    test_config   = select * from TEST_CONFIG;    
    export_config = select * from EXPORT_CONFIG;   

    APLWRAPPER_CREATE_MODEL_AND_TRAIN(:header, :config, :var_desc,:var_role, :dataset_1,out_model,out_log,out_sum,out_indic);
    APLWRAPPER_EXPORT_PROFITCURVES(:header, :out_model, :export_config, out_curves_train);
    APLWRAPPER_TEST_MODEL(:header, :out_model, :test_config, :dataset_2, out_model_2, out_test_log, out_test_indic);
    APLWRAPPER_EXPORT_PROFITCURVES(:header, :out_model_2, :export_config, out_curves_test);
    
    -- store result into table
    insert into  "USER_APL"."MODEL_TEST_BIN_1" select * from :out_model;
    insert into  "USER_APL"."OPERATION_LOG"    select * from :out_log;
    insert into  "USER_APL"."SUMMARY"          select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"       select * from :out_indic;
    insert into  "USER_APL"."MODEL_TEST_BIN_2" select * from :out_model_2;
    insert into  "USER_APL"."TEST_LOG"         select * from :out_test_log;
    insert into  "USER_APL"."TEST_INDICATORS"  select * from :out_test_indic;
	insert into  "USER_APL"."PROFITCURVES_TRAIN"  select * from :out_curves_train;
	insert into  "USER_APL"."PROFITCURVES_TEST"  select * from :out_curves_test;


	-- show result
	select * from "USER_APL"."MODEL_TEST_BIN_1";
	select * from "USER_APL"."OPERATION_LOG";
	select * from "USER_APL"."SUMMARY";
	select * from "USER_APL"."INDICATORS";

	select * from "USER_APL"."MODEL_TEST_BIN_2";
	select * from "USER_APL"."TEST_LOG";
	select * from "USER_APL"."TEST_INDICATORS";

	select * from "USER_APL"."PROFITCURVES_TRAIN";
	select * from "USER_APL"."PROFITCURVES_TEST";
END;