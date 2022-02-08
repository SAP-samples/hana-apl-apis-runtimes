-- ================================================================
-- APL_AREA, GET_TABLE_TYPE_FOR_APPLY, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid and trained model (created by APL) in the MODEL_TRAIN_BIN table.
--               For instance, you have used apl_createmodel_and_train.sql before
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
drop table CALL_SIGNATURE;
create column table CALL_SIGNATURE   like PROCEDURE_SIGNATURE_T;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T',     'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','ADULT01_T',          'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','TABLE_TYPE_T',     'OUT');
insert into CALL_SIGNATURE values (6, 'USER_APL','OPERATION_LOG_T',    'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_GET_TABLE_TYPE_FOR_APPLY');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA', 'GET_TABLE_TYPE_FOR_APPLY', 'USER_APL', 'APLWRAPPER_GET_TABLE_TYPE_FOR_APPLY', CALL_SIGNATURE);


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');

drop table APPLY_CONFIG;
create table APPLY_CONFIG like OPERATION_CONFIG_T;
-- TODO: insert apply configuration parameters (to be defined)

drop table SCHEMA_OUT;
create table SCHEMA_OUT like TABLE_TYPE_T;

drop table SCHEMA_LOG;
create table SCHEMA_LOG like OPERATION_LOG_T;

drop table INPUT_DATA;
create table INPUT_DATA like ADULT01_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    modle_in = select * from MODEL_TRAIN_BIN;             
    config   = select * from APPLY_CONFIG;
    dataset  = select * from INPUT_DATA;

    APLWRAPPER_GET_TABLE_TYPE_FOR_APPLY(:header, :modle_in, :config, :dataset,  out_schema, out_log);
    
    -- store result into table
	insert into  "USER_APL"."SCHEMA_OUT" select * from :out_schema;
    insert into  "USER_APL"."SCHEMA_LOG" select * from :out_log;

	-- show result
	select * from "USER_APL"."SCHEMA_LOG";
	select * from "USER_APL"."SCHEMA_OUT";
END;
