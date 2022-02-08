-- ================================================================
-- APL_AREA, EXPORT_APPLY_CODE
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid and trained model published by Automatedin in the MODELS table.
--  @depend(apl_createmodel_and_train.sql)
connect USER_APL password Password1;

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------

drop table EXPORT_APPLY_CODE_SIGNATURE;
create column table EXPORT_APPLY_CODE_SIGNATURE like PROCEDURE_SIGNATURE_T;

insert into EXPORT_APPLY_CODE_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into EXPORT_APPLY_CODE_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
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

drop table EXPORT_SQL_WITH_EXTRA;
create table EXPORT_SQL_WITH_EXTRA like RESULT_T;

drop table EXPORT_JAVA;
create table EXPORT_JAVA like RESULT_T;

drop table EXPORT_CPP;
create table EXPORT_CPP like RESULT_T;



-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
-- Export SQL for HANA 
drop table EXPORT_CODE_CONFIG_1;
create table EXPORT_CODE_CONFIG_1 like OPERATION_CONFIG_T;
insert into EXPORT_CODE_CONFIG_1 values ('APL/CodeType', 'HANA');
insert into EXPORT_CODE_CONFIG_1 values ('APL/CodeTarget', 'class');
insert into EXPORT_CODE_CONFIG_1 values ('APL/CodeKey', '"id"');
insert into EXPORT_CODE_CONFIG_1 values ('APL/CodeSpace', 'APL_SAMPLES.CENSUS');
insert into EXPORT_CODE_CONFIG_1 values ('APL/ApplyExtraMode', 'No Extra');

-- Export score SQL and stats for HANA 
drop table EXPORT_CODE_CONFIG_2;
create table EXPORT_CODE_CONFIG_2 like OPERATION_CONFIG_T;
insert into EXPORT_CODE_CONFIG_2 values ('APL/CodeType', 'HANA');
insert into EXPORT_CODE_CONFIG_2 values ('APL/CodeTarget', 'class');
insert into EXPORT_CODE_CONFIG_2 values ('APL/CodeKey', '"id"');
insert into EXPORT_CODE_CONFIG_2 values ('APL/CodeSpace', 'APL_SAMPLES.CENSUS');
insert into EXPORT_CODE_CONFIG_2 values ('APL/ApplyExtraMode', 'Min Extra');

-- Export JAVA 
drop table EXPORT_CODE_CONFIG_3;
create table EXPORT_CODE_CONFIG_3 like OPERATION_CONFIG_T;
insert into EXPORT_CODE_CONFIG_3 values ('APL/CodeType', 'JAVA');
insert into EXPORT_CODE_CONFIG_3 values ('APL/CodeTarget', 'class');
insert into EXPORT_CODE_CONFIG_3 values ('APL/CodeClassName', 'ExportedModelInJava');
insert into EXPORT_CODE_CONFIG_3 values ('APL/ApplyExtraMode', 'No Extra');

-- Export C++
drop table EXPORT_CODE_CONFIG_4;
create table EXPORT_CODE_CONFIG_4 like OPERATION_CONFIG_T;
insert into EXPORT_CODE_CONFIG_4 values ('APL/CodeType', 'C++');
insert into EXPORT_CODE_CONFIG_4 values ('APL/CodeTarget', 'class');
insert into EXPORT_CODE_CONFIG_4 values ('APL/CodeClassName', 'ExportedModelInCPP');
insert into EXPORT_CODE_CONFIG_4 values ('APL/ApplyExtraMode', 'No Extra');

DO BEGIN     
    header           = select * from FUNC_HEADER;             
    model_in         = select * from MODEL_TRAIN_BIN;
    export_1_config  = select * from EXPORT_CODE_CONFIG_1; 
    export_2_config  = select * from EXPORT_CODE_CONFIG_2; 
    export_3_config  = select * from EXPORT_CODE_CONFIG_3; 
    export_4_config  = select * from EXPORT_CODE_CONFIG_4; 


    APLWRAPPER_EXPORT_APPLY_CODE(:header, :model_in, :export_1_config, :out_code1);
    APLWRAPPER_EXPORT_APPLY_CODE(:header, :model_in, :export_2_config, :out_code2);
    APLWRAPPER_EXPORT_APPLY_CODE(:header, :model_in, :export_3_config, :out_code3);
    APLWRAPPER_EXPORT_APPLY_CODE(:header, :model_in, :export_4_config, :out_code4);


    -- store result into table
    insert into  "USER_APL"."EXPORT_SQL"            select * from :out_code1;
    insert into  "USER_APL"."EXPORT_SQL_WITH_EXTRA" select * from :out_code2;
    insert into  "USER_APL"."EXPORT_JAVA"           select * from :out_code3;
    insert into  "USER_APL"."EXPORT_CPP"            select * from :out_code4;

	-- show result
    select * from "USER_APL"."EXPORT_SQL";
    select * from "USER_APL"."EXPORT_SQL_WITH_EXTRA";
    select * from "USER_APL"."EXPORT_JAVA";
    select * from "USER_APL"."EXPORT_CPP";
END;
