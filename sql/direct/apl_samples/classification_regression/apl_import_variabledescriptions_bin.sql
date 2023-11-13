-- ================================================================
-- APL_AREA, IMPORT_VARIABLEDESCRIPTIONS
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid model (created by APL) in the MODEL_BIN table.
--               For instance, you have used apl_createmodel.sql before
-- Assumption 4: There're valid variable descriptions (created by APL) in the VARIABLE_DESC_OUT table.
--               For instance, you have used apl_createmodel.sql before
--  @depend(apl_createmodel.sql)

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

-- the AFL wrapper generator needs the signature of the expected stored proc
drop table IMPORT_VARIABLEDESCRIPTIONS_SIGNATURE;
create column table IMPORT_VARIABLEDESCRIPTIONS_SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into IMPORT_VARIABLEDESCRIPTIONS_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into IMPORT_VARIABLEDESCRIPTIONS_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into IMPORT_VARIABLEDESCRIPTIONS_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_T', 'IN');
insert into IMPORT_VARIABLEDESCRIPTIONS_SIGNATURE values (4, 'USER_APL','MODEL_BIN_OID_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_IMPORT_VARIABLEDESCRIPTIONS');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','IMPORT_VARIABLEDESCRIPTIONS','USER_APL', 'APLWRAPPER_IMPORT_VARIABLEDESCRIPTIONS', IMPORT_VARIABLEDESCRIPTIONS_SIGNATURE);



-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');


-- the input variable descriptions are going to be created from an existing table VARIABLE_DESC_OUT, previously populated by a CREATE* APL functions
drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
insert into VARIABLE_DESC (RANK, NAME, STORAGE, VALUETYPE, KEYLEVEL, ORDERLEVEL, MISSINGSTRING, GROUPNAME, DESCRIPTION) select RANK, NAME, STORAGE, VALUETYPE, KEYLEVEL, ORDERLEVEL, MISSINGSTRING, GROUPNAME, DESCRIPTION from VARIABLE_DESC_OUT;
update VARIABLE_DESC set MISSINGSTRING='xxx';
update VARIABLE_DESC set DESCRIPTION='new description for age' where NAME='age';
update VARIABLE_DESC set DESCRIPTION='new description for workclass' where NAME='workclass';
update VARIABLE_DESC set VALUETYPE='ordinal' where NAME='age';
update VARIABLE_DESC set ORDERLEVEL='1' where NAME='fnlwgt';
select * from VARIABLE_DESC;

drop table MODEL2_BIN;
create table MODEL2_BIN like MODEL_BIN_OID_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    modle_in = select * from MODEL_BIN;             
    var_desc = select * from VARIABLE_DESC;

    APLWRAPPER_IMPORT_VARIABLEDESCRIPTIONS(:header, :modle_in, :var_desc, out_model);
    
    -- store result into table
    insert into  "USER_APL"."MODEL2_BIN" select * from :out_model;

	-- show result
    select * from "USER_APL"."MODEL2_BIN";
END;
