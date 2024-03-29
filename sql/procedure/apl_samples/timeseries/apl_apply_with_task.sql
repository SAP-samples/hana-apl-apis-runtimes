-- @required(hanaMinimumVersion,2.0.40)
-- @required(hanaMaximumVersion,2.99.999)
-- ================================================================
-- APL_AREA, FORECAST
-- Description :
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';


-- --------------------------------------------------------------------------
-- Create a view which contains the sorted dataset
-- --------------------------------------------------------------------------

drop view CASHFLOWS_SORTED;
create view CASHFLOWS_SORTED as select * from APL_SAMPLES.CASHFLOWS_FULL order by "Date" asc;

drop table MODEL_BIN_OUT;
create table MODEL_BIN_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table SCHEMA_OUT;
create table SCHEMA_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.TABLE_TYPE";

drop table SCHEMA_LOG;
create table SCHEMA_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table APPLY_OUT;

drop table APPLY_LOG;
create table APPLY_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table APPLY_SUMMARY;
create table APPLY_SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

DO BEGIN
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare apply_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '8'));
    :header.insert(('ModelFormat', 'bin'));
    :header.insert(('CheckOperationConfig', 'true'));
    :header.insert(('MaxTasks', '2'));

    :config.insert(('APL/ModelType', 'timeseries',null));
    :config.insert(('APL/Horizon', '20',null));
    :config.insert(('APL/TimePointColumnName', 'Date',null));
    :config.insert(('APL/LastTrainingTimePoint', '2001-12-29 00:00:00',null));
    :config.insert(('APL/WithExtraPredictable', 'false',null));
    :config.insert(('APL/ForcePositiveForecast', 'true',null));

    :var_role.insert(('Date', 'input',null,null,null));
    :var_role.insert(('Cash', 'target',null,null,null));
    
    :apply_config.insert(('APL/ApplyLastTimePoint', '2001-12-29 00:00:00',null));

    insert into :var_desc select *,'42' from APL_SAMPLES.CASHFLOWS_DESC;    
          
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role, 'USER_APL','CASHFLOWS_SORTED', model,  train_log, train_sum, train_indic);          
    "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY" (:header, :model, :apply_config, 'USER_APL','CASHFLOWS_SORTED',  out_schema, out_log);
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_TABLE_FROM_TABLE_TYPE"('USER_APL','APPLY_OUT',:out_schema);
    "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL"(:header, :model, :apply_config, 'USER_APL','CASHFLOWS_SORTED', 'USER_APL', 'APPLY_OUT', out_apply_log, out_apply_sum);

    -- store result into table
    insert into  "USER_APL"."MODEL_BIN_OUT"   select * from :model;
    insert into  "USER_APL"."OPERATION_LOG"   select * from :train_log;
    insert into  "USER_APL"."SUMMARY"         select * from :train_sum;
    insert into  "USER_APL"."INDICATORS"      select * from :train_indic;
    insert into  "USER_APL"."SCHEMA_OUT"      select * from :out_schema;
    insert into  "USER_APL"."APPLY_LOG"       select * from :out_apply_log;
    insert into  "USER_APL"."APPLY_SUMMARY"   select * from :out_apply_sum;

END;

select * from "USER_APL"."MODEL_BIN_OUT";
select * from "USER_APL"."OPERATION_LOG";
select * from "USER_APL"."SUMMARY";
select * from "USER_APL"."INDICATORS";
select * from "USER_APL"."SCHEMA_OUT" order by POSITION;
select * from "USER_APL"."APPLY_LOG";
select * from "USER_APL"."APPLY_SUMMARY";
