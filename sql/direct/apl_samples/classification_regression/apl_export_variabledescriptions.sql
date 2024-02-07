-- ================================================================
-- APL_AREA, EXPORT_VARIABLEDESCRIPTIONS
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid model (created by APL) in the MODEL_BIN table.
--               For instance, apl_createmodel.sql before
--  @depend(apl_createmodel.sql)
-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

-- the AFL wrapper generator needs the signature of the expected stored proc
drop table EXPORT_VARIABLEDESCRIPTIONS_SIGNATURE;
create table EXPORT_VARIABLEDESCRIPTIONS_SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into EXPORT_VARIABLEDESCRIPTIONS_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into EXPORT_VARIABLEDESCRIPTIONS_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into EXPORT_VARIABLEDESCRIPTIONS_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_OID_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_EXPORT_VARIABLEDESCRIPTIONS');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','EXPORT_VARIABLEDESCRIPTIONS','USER_APL', 'APLWRAPPER_EXPORT_VARIABLEDESCRIPTIONS', EXPORT_VARIABLEDESCRIPTIONS_SIGNATURE);



-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table VARIABLE_DESC_OUT;
create table VARIABLE_DESC_OUT like VARIABLE_DESC_OID_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    modle_in = select * from MODEL_BIN;             

    APLWRAPPER_EXPORT_VARIABLEDESCRIPTIONS(:header, :modle_in, out_var_desc);
    
    -- store result into table
	insert into  "USER_APL"."VARIABLE_DESC_OUT" select * from :out_var_desc;

	-- show result
	select * from "USER_APL"."VARIABLE_DESC_OUT";
END;
