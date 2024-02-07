-- ================================================================
-- APL_AREA, EXPORT_APPLY_CODE, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

-- Assumption 2: There's a valid and trained classification model (created by APL) in the MODEL_TRAIN_BIN table.
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
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

-- --------------------------------------------------------------------------
-- Export SQL for HANA 
-- --------------------------------------------------------------------------
drop table EXPORT_SQL;
create table EXPORT_SQL like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.RESULT";

drop table EXPORT_CONFIG;
create table EXPORT_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into EXPORT_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);
insert into EXPORT_CONFIG values ('APL/ApplyProba','true',null); 
insert into EXPORT_CONFIG values ('APL/ApplyBar','true',null);
insert into EXPORT_CONFIG values ('APL/ApplyDecision','true',null);
insert into EXPORT_CONFIG values ('APL/ApplyProbaDecision','true',null);
insert into EXPORT_CONFIG values ('APL/ApplyContribution','education;occupation',null);

insert into EXPORT_CONFIG values ('APL/CodeType', 'HANA',null);
insert into EXPORT_CONFIG values ('APL/CodeTarget', 'class',null);
insert into EXPORT_CONFIG values ('APL/CodeKey', '"id"',null);
insert into EXPORT_CONFIG values ('APL/CodeSpace', 'APL_SAMPLES.CENSUS',null);

DO BEGIN     
    header           = select * from FUNC_HEADER;             
    model_in         = select * from MODEL_TRAIN_BIN;
    export_config    = select * from EXPORT_CONFIG; 

    "SAP_PA_APL"."sap.pa.apl.base::EXPORT_APPLY_CODE"(:header, :model_in, :export_config, :out_code1);
 
    -- store result into table
    insert into  "USER_APL"."EXPORT_SQL"            select * from :out_code1;

	-- show result
    select * from "USER_APL"."EXPORT_SQL";
END;
