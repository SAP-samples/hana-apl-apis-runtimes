-- @required(hanaMinimumVersion,2.0.40)
-- ================================================================
-- APL_AREA, FORECAST
-- Description :
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';


-- --------------------------------------------------------------------------
-- Create a view which contains the sorted dataset
-- --------------------------------------------------------------------------

drop view CASHFLOWS_TRAIN_SORTED;
create view CASHFLOWS_TRAIN_SORTED as select * from APL_SAMPLES.CASHFLOWS_FULL where "Date" <= '2001-12-28 00:00:00' order by "Date" asc;

drop view CASHFLOWS_APPLIN_SORTED;
create view CASHFLOWS_APPLIN_SORTED as select * from APL_SAMPLES.CASHFLOWS_FULL where "Date" >= '2001-12-28 00:00:00'  order by "Date" asc;


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table MODEL_BIN_OUT;
create table MODEL_BIN_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table TRAIN_LOG;
create table TRAIN_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table SCHEMA_OUT;
create COLUMN table SCHEMA_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.TABLE_TYPE";

drop table SCHEMA_LOG;
create COLUMN table SCHEMA_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table APPLY_OUT;

drop table APPLY_LOG;
create column table APPLY_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table APPLY_SUMMARY;
create column table APPLY_SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";
DO BEGIN
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare apply_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      
     
    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '8'));
    :header.insert(('ModelFormat', 'bin'));

    :config.insert(('APL/ModelType', 'timeseries',null));
    :config.insert(('APL/Horizon', '10',null));
    :config.insert(('APL/TimePointColumnName', 'Date',null));
    :config.insert(('APL/LastTrainingTimePoint', '2001-12-28 00:00:00',null));
    :config.insert(('APL/WithExtraPredictable', 'true',null));

    :var_role.insert(('Date', 'input',null,null,null));
    :var_role.insert(('Cash', 'target',null,null,null));

    :apply_config.insert(('APL/ApplyLastTimePoint', '2001-12-28 00:00:00',null));
    :apply_config.insert(('APL/AppliedHorizon', '10',null));


    insert into :var_desc select *,'42' from APL_SAMPLES.CASHFLOWS_DESC;    

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role, 'USER_APL','CASHFLOWS_TRAIN_SORTED', model,  train_log, train_sum, train_indic);          
    "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY" (:header, :model, :apply_config, 'USER_APL','CASHFLOWS_APPLIN_SORTED',  out_schema, out_log);
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_TABLE_FROM_TABLE_TYPE"('USER_APL','APPLY_OUT',:out_schema);
    "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL"(:header, :model, :apply_config, 'USER_APL','CASHFLOWS_APPLIN_SORTED', 'USER_APL', 'APPLY_OUT', out_apply_log, out_apply_sum);

    -- store result into table
    insert into  "USER_APL"."MODEL_BIN_OUT"   select * from :model;
    insert into  "USER_APL"."TRAIN_LOG"       select * from :train_log;
    insert into  "USER_APL"."APPLY_LOG"       select * from :out_apply_log;
    insert into  "USER_APL"."APPLY_SUMMARY"   select * from :out_apply_sum;
END;

DO BEGIN
   	declare nb_dates integer;
    select count(*) into nb_dates  from "USER_APL"."APPLY_OUT" A, ( select * from "USER_APL"."CASHFLOWS_APPLIN_SORTED" order by "Date" limit 11) B  where  A."Date" = B."Date";

    if ( :nb_dates != 11 ) then
         SIGNAL SQL_ERROR_CODE 10000 SET MESSAGE_TEXT = 'Wrong Number of Date in ApplyOut';
    end if;
END;
