-- ================================================================
-- APL_AREA, EXPORT_APPLY_CODE
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

-- Assumption 3: There's a valid and trained model (created by APL) in the MODEL_TRAIN_BIN table.
--               For instance, you have used apl_createmodel_and_train_ex.sql before
--  @depend(apl_createmodel_and_train_ex.sql)
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";

drop table EXPORT_SQL;
create table EXPORT_SQL like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.RESULT";

drop table EXPORT_SQL_WITH_EXTRA;
create table EXPORT_SQL_WITH_EXTRA like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.RESULT";

drop table EXPORT_JAVA;
create table EXPORT_JAVA like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.RESULT";

drop table EXPORT_CPP;
create table EXPORT_CPP like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.RESULT";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------

-- Export SQL for HANA 
drop table EXPORT_CODE_CONFIG_1;
create table EXPORT_CODE_CONFIG_1 like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into EXPORT_CODE_CONFIG_1 values ('APL/CodeType', 'HANA',null);
insert into EXPORT_CODE_CONFIG_1 values ('APL/CodeTarget', 'class',null);
insert into EXPORT_CODE_CONFIG_1 values ('APL/CodeKey', '"id"',null);
insert into EXPORT_CODE_CONFIG_1 values ('APL/CodeSpace', 'APL_SAMPLES.CENSUS',null);
insert into EXPORT_CODE_CONFIG_1 values ('APL/ApplyExtraMode', 'No Extra',null);

-- Export score SQL and stats for HANA 
drop table EXPORT_CODE_CONFIG_2;
create table EXPORT_CODE_CONFIG_2 like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into EXPORT_CODE_CONFIG_2 values ('APL/CodeType', 'HANA',null);
insert into EXPORT_CODE_CONFIG_2 values ('APL/CodeTarget', 'class',null);
insert into EXPORT_CODE_CONFIG_2 values ('APL/CodeKey', '"id"',null);
insert into EXPORT_CODE_CONFIG_2 values ('APL/CodeSpace', 'APL_SAMPLES.CENSUS',null);
insert into EXPORT_CODE_CONFIG_2 values ('APL/ApplyExtraMode', 'Min Extra',null);

-- Export JAVA 
drop table EXPORT_CODE_CONFIG_3;
create table EXPORT_CODE_CONFIG_3 like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into EXPORT_CODE_CONFIG_3 values ('APL/CodeType', 'JAVA',null);
insert into EXPORT_CODE_CONFIG_3 values ('APL/CodeTarget', 'class',null);
insert into EXPORT_CODE_CONFIG_3 values ('APL/CodeClassName', 'ExportedModelInJava',null);
insert into EXPORT_CODE_CONFIG_3 values ('APL/ApplyExtraMode', 'No Extra',null);


drop table EXPORT_CODE_CONFIG_4;
create table EXPORT_CODE_CONFIG_4 like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into EXPORT_CODE_CONFIG_4 values ('APL/CodeType', 'C++',null);
insert into EXPORT_CODE_CONFIG_4 values ('APL/CodeTarget', 'class',null);
insert into EXPORT_CODE_CONFIG_4 values ('APL/CodeClassName', 'ExportedModelInCPP',null);
insert into EXPORT_CODE_CONFIG_4 values ('APL/ApplyExtraMode', 'No Extra',null);

DO BEGIN SEQUENTIAL EXECUTION    
    header           = select * from FUNC_HEADER;             
    model_in         = select * from MODEL_TRAIN_BIN;
    export_1_config  = select * from EXPORT_CODE_CONFIG_1; 
    export_2_config  = select * from EXPORT_CODE_CONFIG_2; 
    export_3_config  = select * from EXPORT_CODE_CONFIG_3; 
    export_4_config  = select * from EXPORT_CODE_CONFIG_4; 


    "SAP_PA_APL"."sap.pa.apl.base::EXPORT_APPLY_CODE"(:header, :model_in, :export_1_config, :out_code1);
    "SAP_PA_APL"."sap.pa.apl.base::EXPORT_APPLY_CODE"(:header, :model_in, :export_2_config, :out_code2);
    "SAP_PA_APL"."sap.pa.apl.base::EXPORT_APPLY_CODE"(:header, :model_in, :export_3_config, :out_code3);
    "SAP_PA_APL"."sap.pa.apl.base::EXPORT_APPLY_CODE"(:header, :model_in, :export_4_config, :out_code4);


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
