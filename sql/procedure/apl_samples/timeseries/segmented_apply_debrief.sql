-- @required(hanaMinimumVersion,2.0.40)
-- ================================================================
-- APL_AREA, APPLY_MODEL, using a binary format for the model
-- This script demonstrates the application of the binary classification model
-- to predict the target and to get the individual contributions per input
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(segmented_create_train.sql)
--  @depend(apl_apply_proc.sql)
connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

drop table APPLY_OPERATION_LOG;
create table APPLY_OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table APPLY_SUMMARY;
create table APPLY_SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table APPLY_DEBRIEF_METRIC;
create table APPLY_DEBRIEF_METRIC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";

drop table APPLY_DEBRIEF_PROPERTY;
create table APPLY_DEBRIEF_PROPERTY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";


DO BEGIN
    declare header  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare apply_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
    declare model   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";
    declare out_log "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";
    declare out_sum "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";
    declare out_debrief_metric   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";
    declare out_debrief_property "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";
   
    insert into :model select * from MODEL_TRAIN_BIN;

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '8'));
    :header.insert(('ModelFormat', 'bin'));
    :header.insert(('CheckOperationConfig', 'true'));
    :header.insert(('MaxTasks', '2'));  -- define nb parallel tasks to use for train

    :apply_config.insert(('APL/SegmentColumnName', 'Seg',null)); -- define the column used as the segmentation colum
    :apply_config.insert(('APL/ApplyLastTimePoint', '2001-12-29 00:00:00',null));
    :apply_config.insert(('APL/AppliedHorizon', '14',null));
    :apply_config.insert(('APL/LocalExplanations/Activate', 'true',null));
    :apply_config.insert(('APL/ApplyExtraMode', 'First Forecast with Stable Components and Residues and Error Bars',null));

    call "apl_apply_debrief_example"(:header, :model,  :apply_config, 'USER_APL','CASHFLOWS_SORTED', 'USER_APL','APPLY_OUT',out_log,out_sum,out_debrief_metric, out_debrief_property);

    insert into  APPLY_OPERATION_LOG    select * from :out_log;
    insert into  APPLY_SUMMARY          select * from :out_sum;
    insert into  APPLY_DEBRIEF_PROPERTY select * from :out_debrief_property;
    insert into  APPLY_DEBRIEF_METRIC   select * from :out_debrief_metric;    
END;

--SELECT * from CASHFLOWS_SORTED;
SELECT "Seg", count(*) from APPLY_OUT group by "Seg";

-- Nb trained models   
select count(*) from  APPLY_SUMMARY where "KEY" = 'AplTaskElapsedTime';

-- Average time to train a segment  
select AVG(to_double("VALUE")) from APPLY_SUMMARY where "KEY" = 'AplTaskElapsedTime';

-- Total time 
select * from APPLY_SUMMARY where "KEY" = 'AplTotalElapsedTime';

-- Get models in error
select * from APPLY_OPERATION_LOG where "LEVEL" = 0;

select * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_ForecastBreakdown"(APPLY_DEBRIEF_PROPERTY, APPLY_DEBRIEF_METRIC);
