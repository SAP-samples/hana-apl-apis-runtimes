-- ================================================================
-- APL_AREA, EXPORT_APPLY_CODE
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid and published model in the MODELS table.
--               For instance, you have used apl_publish.sql before.
--  @depend(apl_publish.sql)
connect USER_APL password Password1;

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------

drop table UPDATE_MODEL_SIGNATURE;
create column table UPDATE_MODEL_SIGNATURE like PROCEDURE_SIGNATURE_T;

insert into UPDATE_MODEL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into UPDATE_MODEL_SIGNATURE values (2, 'USER_APL','MODEL_NATIVE_T', 'IN');
insert into UPDATE_MODEL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into UPDATE_MODEL_SIGNATURE values (4, 'USER_APL','MODEL_BIN_OID_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_UPDATE_MODEL_1');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','UPDATE_MODEL','USER_APL', 'APLWRAPPER_UPDATE_MODEL_1', UPDATE_MODEL_SIGNATURE);

delete from  UPDATE_MODEL_SIGNATURE;
insert into UPDATE_MODEL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into UPDATE_MODEL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into UPDATE_MODEL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into UPDATE_MODEL_SIGNATURE values (4, 'USER_APL','MODEL_BIN_OID_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_UPDATE_MODEL_2');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','UPDATE_MODEL','USER_APL', 'APLWRAPPER_UPDATE_MODEL_2', UPDATE_MODEL_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table EXPORT_SQL;
create table EXPORT_SQL like RESULT_T;

drop table MODEL_UPDATED_BIN;
create table MODEL_UPDATED_BIN like MODEL_BIN_OID_T;

drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like MODEL_BIN_OID_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
drop table UPDATE_CONFIG;
create table UPDATE_CONFIG like OPERATION_CONFIG_T;

DO BEGIN     
    header           = select * from FUNC_HEADER;             
    config           = select * from UPDATE_CONFIG;  
    model_in         = select * from  "MODELS"  order by "ID" asc;

    APLWRAPPER_UPDATE_MODEL_1(:header, :model_in,    :config, out_model_1);
    APLWRAPPER_UPDATE_MODEL_2(:header, :out_model_1, :config, out_model_2);

    -- store result into table
    insert into  "USER_APL"."MODEL_UPDATED_BIN"   select * from :out_model_1;
    insert into  "USER_APL"."MODEL_TRAIN_BIN"     select * from :out_model_2;

	-- show result
    select * from "USER_APL"."MODEL_UPDATED_BIN";
    select * from "USER_APL"."MODEL_TRAIN_BIN";
END;
