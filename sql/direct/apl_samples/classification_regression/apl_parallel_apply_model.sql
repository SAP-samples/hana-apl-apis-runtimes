-- @required(hanaMinimumVersion,20SP0)
-- ================================================================
-- APL_AREA, PARALLEL APPLY_MODEL, using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
-- Assumption 4: You are using Hana 2.0+ and running APL built with AFL SDK 2.0
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

-- Ouput table type: dataset
drop type ADULT01_T_OUT;
create type ADULT01_T_OUT as table (
    "KxIndex" INTEGER,
    "class" INTEGER,
    "rr_class" DOUBLE
);


-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
-- the AFL wrapper generator needs the signature of the expected stored proc
drop table APPLY_MODEL_SIGNATURE;
create column table APPLY_MODEL_SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into APPLY_MODEL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into APPLY_MODEL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T',     'IN');
insert into APPLY_MODEL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into APPLY_MODEL_SIGNATURE values (4, 'USER_APL','ADULT01_T',          'IN');
insert into APPLY_MODEL_SIGNATURE values (5, 'USER_APL','ADULT01_T_OUT',      'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_APPLY_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','PARALLEL_APPLY_MODEL','USER_APL', 'APLWRAPPER_APPLY_MODEL', APPLY_MODEL_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');


drop table APPLY_CONFIG;
create table APPLY_CONFIG like OPERATION_CONFIG_T;
-- TODO: insert training configuration parameters (to be defined)

drop table ADULT01_APPLY;
create column table ADULT01_APPLY like ADULT01_T_OUT;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header       = select * from FUNC_HEADER;             
    model_in     = select * from MODEL_TRAIN_BIN; 	           
    apply_config = select * from APPLY_CONFIG; 	           
    dataset      = select * from APL_SAMPLES.ADULT01;  

    call APLWRAPPER_APPLY_MODEL(:header, :model_in, :apply_config,  :dataset, out_apply) WITH HINT(PARALLEL_BY_PARAMETER_PARTITIONS(p4));

    -- store result into table
    insert into  "USER_APL"."ADULT01_APPLY"   select * from :out_apply;

	-- show result
	select * from "USER_APL"."ADULT01_APPLY";
END;
