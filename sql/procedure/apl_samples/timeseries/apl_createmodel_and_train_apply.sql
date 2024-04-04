-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create a view which contains the sorted dataset
-- --------------------------------------------------------------------------

drop view CASHFLOWS_SORTED;
create view CASHFLOWS_SORTED as select * from APL_SAMPLES.CASHFLOWS_FULL order by "Date" asc;


-- USER_APL.APPLY_OUT definition
drop type APPLY_T_OUT;
create type APPLY_T_OUT as table (
    "Date" DATE,
    "Cash" DECIMAL(17,6),
	"kts_1" DOUBLE,
	"kts_2" DOUBLE,
	"kts_3" DOUBLE,
	"kts_4" DOUBLE
);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table DEBRIEF_METRIC;
create table DEBRIEF_METRIC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";

drop table DEBRIEF_PROPERTY;
create table DEBRIEF_PROPERTY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";

drop table APPLY_OUT;
create table APPLY_OUT like APPLY_T_OUT;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
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

    :config.insert(('APL/ModelType', 'timeseries',null));
    :config.insert(('APL/Horizon', '4',null));
    :config.insert(('APL/TimePointColumnName', 'Date',null));
    :config.insert(('APL/LastTrainingTimePoint', '2001-12-29 00:00:00',null));
    :config.insert(('APL/ApplyLastTimePoint', '2001-12-29 00:00:00',null));
    :config.insert(('APL/WithExtraPredictable', 'false',null));
    :config.insert(('APL/ForcePositiveForecast', 'true',null));

    :var_role.insert(('Date', 'input',null,null,null));
    :var_role.insert(('Cash', 'target',null,null,null));

    insert into :var_desc select *,'42' from APL_SAMPLES.CASHFLOWS_DESC;

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN_APPLY"(:header, :config, :var_desc,:var_role, 'USER_APL','CASHFLOWS_SORTED', 'USER_APL','CASHFLOWS_SORTED',  'USER_APL','APPLY_OUT', out_model, out_log, out_sum, out_debrief_metric, out_debrief_property);     
    
    insert into  "USER_APL"."MODEL_TRAIN_BIN" select * from :out_model;
    insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;
    insert into  "USER_APL"."SUMMARY"         select * from :out_sum;
    insert into  "USER_APL"."DEBRIEF_METRIC"   select * from :out_debrief_metric;
    insert into  "USER_APL"."DEBRIEF_PROPERTY" select * from :out_debrief_property;

    select * from "USER_APL"."APPLY_OUT";
    select * from "USER_APL"."MODEL_TRAIN_BIN";
    select * from "USER_APL"."OPERATION_LOG";
    select * from "USER_APL"."SUMMARY";
    select * from "USER_APL"."DEBRIEF_METRIC";
    select * from "USER_APL"."DEBRIEF_PROPERTY";
END;
