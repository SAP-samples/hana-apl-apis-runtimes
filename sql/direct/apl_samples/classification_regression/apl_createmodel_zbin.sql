-- @required(hanaMinimumVersion,2.0.30)
-- ================================================================
-- APL_AREA, CREATE_MODEL, using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).


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
drop table CREATE_MODEL_SIGNATURE;
create column table CREATE_MODEL_SIGNATURE  like PROCEDURE_SIGNATURE_T;
insert into CREATE_MODEL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CREATE_MODEL_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CREATE_MODEL_SIGNATURE values (3, 'USER_APL','ADULT01_T', 'IN');
insert into CREATE_MODEL_SIGNATURE values (4, 'USER_APL','MODEL_ZBIN_T', 'OUT');
insert into CREATE_MODEL_SIGNATURE values (5, 'USER_APL','VARIABLE_DESC_OID_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_CREATE_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','CREATE_MODEL','USER_APL', 'APLWRAPPER_CREATE_MODEL', CREATE_MODEL_SIGNATURE);


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'zbin');

drop table CREATE_CONFIG;
create table CREATE_CONFIG like OPERATION_CONFIG_T;
insert into CREATE_CONFIG values ('APL/ModelType', 'regression/classification');

drop table MODEL_ZBIN;
create table MODEL_ZBIN like MODEL_ZBIN_T;

drop table VARIABLE_DESC_OUT;
create table VARIABLE_DESC_OUT like VARIABLE_DESC_OID_T;


-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from CREATE_CONFIG;  
    dataset  = select * from APL_SAMPLES.ADULT01; 
	
    APLWRAPPER_CREATE_MODEL(:header, :config,:dataset,out_model,out_var_desc);

    -- store result into table
    insert into  "USER_APL"."MODEL_ZBIN"          select * from :out_model;
    insert into  "USER_APL"."VARIABLE_DESC_OUT"  select * from :out_var_desc;

	-- show result
	select * from "USER_APL"."MODEL_ZBIN";
	select * from "USER_APL"."VARIABLE_DESC_OUT";
END;
