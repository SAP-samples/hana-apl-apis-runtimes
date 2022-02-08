-- ================================================================
-- APL_AREA, TEST_MODEL, using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(apl_createmodel_and_train.sql)

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
drop table TEST_MODEL_SIGNATURE;
create column table TEST_MODEL_SIGNATURE like PROCEDURE_SIGNATURE_T;

insert into TEST_MODEL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into TEST_MODEL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T',     'IN');
insert into TEST_MODEL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into TEST_MODEL_SIGNATURE values (4, 'USER_APL','ADULT01_T',          'IN');
insert into TEST_MODEL_SIGNATURE values (5, 'USER_APL','MODEL_BIN_OID_T',    'OUT');
insert into TEST_MODEL_SIGNATURE values (6, 'USER_APL','OPERATION_LOG_T',    'OUT');
insert into TEST_MODEL_SIGNATURE values (7, 'USER_APL','INDICATORS_T',       'OUT');


call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_TEST_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','TEST_MODEL', 'USER_APL', 'APLWRAPPER_TEST_MODEL', TEST_MODEL_SIGNATURE);


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('ModelFormat', 'bin');


drop table TEST_CONFIG;
create table TEST_CONFIG like OPERATION_CONFIG_T;

drop table TEST_MODEL_BIN;
create table TEST_MODEL_BIN like MODEL_BIN_OID_T;

drop table TEST_LOG;
create column table TEST_LOG like OPERATION_LOG_T;

drop table TEST_INDICATORS;
create table TEST_INDICATORS like INDICATORS_T;


-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;
	model_in = select * from MODEL_TRAIN_BIN;
    test_config = select * from TEST_CONFIG;            
    dataset  = select * from APL_SAMPLES.ADULT01;  

	APLWRAPPER_TEST_MODEL(:header, :model_in, :test_config, :dataset, out_model, out_test_log, out_test_indic);
    
    -- store result into table
    insert into  "USER_APL"."TEST_MODEL_BIN"   select * from :out_model;
    insert into  "USER_APL"."TEST_LOG"         select * from :out_test_log;
    insert into  "USER_APL"."TEST_INDICATORS"  select * from :out_test_indic;

	-- show result
	select * from "USER_APL"."TEST_MODEL_BIN";
	select * from "USER_APL"."TEST_LOG";
	select * from "USER_APL"."TEST_INDICATORS";
END;