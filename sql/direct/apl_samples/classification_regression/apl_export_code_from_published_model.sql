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

drop table EXPORT_APPLY_CODE_SIGNATURE;
create table EXPORT_APPLY_CODE_SIGNATURE like PROCEDURE_SIGNATURE_T;

insert into EXPORT_APPLY_CODE_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into EXPORT_APPLY_CODE_SIGNATURE values (2, 'USER_APL','MODEL_NATIVE_T', 'IN');
insert into EXPORT_APPLY_CODE_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into EXPORT_APPLY_CODE_SIGNATURE values (4, 'USER_APL','RESULT_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_EXPORT_APPLY_CODE');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','EXPORT_APPLY_CODE','USER_APL', 'APLWRAPPER_EXPORT_APPLY_CODE', EXPORT_APPLY_CODE_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;

drop table EXPORT_SQL;
create table EXPORT_SQL like RESULT_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
drop view MODEL_SORTED;
create view MODEL_SORTED AS SELECT *  from MODELS where NAME = 'Train Model' and VERSION = 1 order by "ID" asc  ;

-- Export SQL for HANA 
drop table EXPORT_CONFIG;
create table EXPORT_CONFIG like OPERATION_CONFIG_T;
insert into EXPORT_CONFIG values ('APL/CodeType', 'HANA');
insert into EXPORT_CONFIG values ('APL/ApplyExtraMode', 'No Extra');

DO BEGIN     
    header           = select * from FUNC_HEADER;             
    model_in         = select * from MODEL_SORTED;
    export_config    = select * from EXPORT_CONFIG; 

    APLWRAPPER_EXPORT_APPLY_CODE(:header, :model_in, :export_config, :out_code1);

    -- store result into table
    insert into  "USER_APL"."EXPORT_SQL"            select * from :out_code1;

	-- show result
    select * from "USER_APL"."EXPORT_SQL";
END;
