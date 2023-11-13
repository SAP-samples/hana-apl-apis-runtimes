-- @required(hanaMinimumVersion,2.0.40)
-- ================================================================
-- APL_AREA, APPLY_MODEL, using a binary format for the model
-- This script demonstrates the application of the binary classification model
-- to predict the target and to get the individual contributions per input
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(segmented_create_train.sql)
connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

drop table TEST_SUMMARY;
create table TEST_SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table TEST_METRIC;
create table TEST_METRIC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";

drop table TEST_PROPERTY;
create table TEST_PROPERTY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";

drop table TEST_MODEL_BIN;
create table TEST_MODEL_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table TEST_OPERATION_LOG;
create table TEST_OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

DO BEGIN     
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare model "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";      
    declare out_model "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID"; 
    declare out_log   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";             
    declare out_summary  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";      
    declare out_metric   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";      
    declare out_property "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";      

    model = select * from MODEL_TRAIN_BIN;

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '2'));
    :header.insert(('CheckOperationConfig', 'true'));
    :header.insert(('MaxTasks', '2'));  -- define nb parallel tasks to use for train

    :config.insert(('APL/SegmentColumnName', 'Seg',null)); -- define the column used as the segmentation colum

    "SAP_PA_APL"."sap.pa.apl.base::TEST_MODEL_DEBRIEF"(:header, :model, :config,'USER_APL','ADULT01_SORTED', out_model, out_log, out_summary, out_metric,out_property);

    -- store result into table
	insert into  TEST_PROPERTY       select * from :out_property;
	insert into  TEST_METRIC         select * from :out_metric;
    insert into  TEST_SUMMARY        select * from :out_summary;
    insert into  TEST_MODEL_BIN      select * from :out_model;
    insert into  TEST_OPERATION_LOG  select * from :out_log;
END;

select * from  TEST_MODEL_BIN;
select * from  TEST_OPERATION_LOG;

-- Nb trained models   
select count(*) from  TEST_SUMMARY where "KEY" = 'AplTaskElapsedTime';

-- Average time to train a segment  
select AVG(to_double("VALUE")) from TEST_SUMMARY where "KEY" = 'AplTaskElapsedTime';

-- Total time 
select * from TEST_SUMMARY where "KEY" = 'AplTotalElapsedTime';

-- Debrief all models by segment
select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::ClassificationRegression_Performance"(TEST_PROPERTY, TEST_METRIC);
