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
drop table GET_VARIABLE_INDICATORS_SIGNATURE;
create column table GET_VARIABLE_INDICATORS_SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into GET_VARIABLE_INDICATORS_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into GET_VARIABLE_INDICATORS_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into GET_VARIABLE_INDICATORS_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into GET_VARIABLE_INDICATORS_SIGNATURE values (4, 'USER_APL','INDICATORS_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_GET_VARIABLE_INDICATORS');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','GET_VARIABLE_INDICATORS','USER_APL', 'APLWRAPPER_GET_VARIABLE_INDICATORS', GET_VARIABLE_INDICATORS_SIGNATURE);


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');


drop table OPERATION_CONFIG;
create table OPERATION_CONFIG like OPERATION_CONFIG_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    modle_in = select * from MODEL_TRAIN_BIN;             
    config   = select * from OPERATION_CONFIG;

    APLWRAPPER_GET_VARIABLE_INDICATORS(:header, :modle_in, :config, out_indicators);
    
    -- store result into table
	insert into  "USER_APL"."INDICATORS" select * from :out_indicators;

	-- show result
    select * from "USER_APL"."INDICATORS";
END;
