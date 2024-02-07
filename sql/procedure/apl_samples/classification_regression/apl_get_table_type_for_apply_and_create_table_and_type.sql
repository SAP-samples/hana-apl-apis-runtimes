-- ================================================================
-- APL_AREA, GET_TABLE_TYPE_FOR_APPLY, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

-- Assumption 2: There's a valid and trained model (created by APL) in the MODEL_TRAIN_BIN table.
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

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);
insert into APPLY_CONFIG values ('APL/ApplyProba','true',null); 
insert into APPLY_CONFIG values ('APL/ApplyBar','true',null);
insert into APPLY_CONFIG values ('APL/ApplyDecision','true',null);
insert into APPLY_CONFIG values ('APL/ApplyProbaDecision','true',null);

-- Contribution
insert into APPLY_CONFIG values ('APL/ApplyContribution','education;occupation',null);

-- Copy Variables
insert into APPLY_CONFIG values ('APL/ApplyCopyVariables','education;occupation',null);

drop table SCHEMA_OUT;
create table SCHEMA_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.TABLE_TYPE";

drop table SCHEMA_LOG;
create table SCHEMA_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table "USER_APL"."APPLY_OUT";
drop type "USER_APL"."TYPE_OUT";
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    modle_in = select * from MODEL_TRAIN_BIN;             
    config   = select * from APPLY_CONFIG;

    "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY" (:header, :modle_in, :config, 'APL_SAMPLES','ADULT01',  out_schema, out_log);

    -- --------------------------------------------------------------------------
    -- Create table from SCHEMA_OUT
    -- --------------------------------------------------------------------------
    call "SAP_PA_APL"."sap.pa.apl.base::CREATE_TABLE_FROM_TABLE_TYPE"('USER_APL','APPLY_OUT',:out_schema);

    -- --------------------------------------------------------------------------
    -- Create table type from SCHEMA_OUT
    -- --------------------------------------------------------------------------
    call "SAP_PA_APL"."sap.pa.apl.base::CREATE_TYPE_FROM_TABLE_TYPE"('USER_APL','TYPE_OUT',:out_schema);

END;
