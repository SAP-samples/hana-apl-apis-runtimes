-- ================================================================
-- APL_AREA, GET_VARIABLE_INDICATORS, using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(apl_createmodel_and_train.sql)

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
connect USER_APL password Password1;
-- the AFL wrapper generator needs the signature of the expected stored proc
drop table SIGNATURE;
create column table SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into SIGNATURE values (4, 'USER_APL','TABLE_TYPE_T',     'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_GET_MODEL_DATASET_TYPES');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','GET_MODEL_DATASET_TYPES','USER_APL', 'APLWRAPPER_GET_MODEL_DATASET_TYPES', SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

drop table OPERATION_CONFIG;
create table OPERATION_CONFIG like OPERATION_CONFIG_T;


drop table TRAINING_SIGNATURE;
create table TRAINING_SIGNATURE like TABLE_TYPE_T;


-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    modle_in = select * from MODEL_TRAIN_BIN;             
    config    = select * from OPERATION_CONFIG;          

    APLWRAPPER_GET_MODEL_DATASET_TYPES(:header, :modle_in, :config, out_schema);
    
    -- store result into table
	insert into  "USER_APL"."TRAINING_SIGNATURE" select * from :out_schema;

	-- show result
    select * from "USER_APL"."TRAINING_SIGNATURE";
END;
