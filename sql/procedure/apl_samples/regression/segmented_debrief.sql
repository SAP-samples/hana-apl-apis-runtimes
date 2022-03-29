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

drop table DEBRIEF_SUMMARY;
create table DEBRIEF_SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table DEBRIEF_METRIC;
create table DEBRIEF_METRIC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";

drop table DEBRIEF_PROPERTY;
create table DEBRIEF_PROPERTY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";

DO BEGIN     
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare model "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";      
    declare out_debrief_summary  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";      
    declare out_debrief_metric   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";      
    declare out_debrief_property "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";      

	model = select * from MODEL_TRAIN_BIN;

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '2'));
    :header.insert(('MaxTasks', '4'));  -- define nb parallel tasks to use for train

    :config.insert(('APL/SegmentColumnName', 'Seg',null)); -- define the column used as the segmentation colum

	call "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_DEBRIEF"(:header, :model, :config, out_debrief_metric, out_debrief_property, out_debrief_summary);
	
	-- store result into table
	insert into  DEBRIEF_PROPERTY       select * from :out_debrief_property;
	insert into  DEBRIEF_METRIC         select * from :out_debrief_metric;
    insert into  DEBRIEF_SUMMARY        select * from :out_debrief_summary;
END;

-- Nb trained models   
select count(*) from  DEBRIEF_SUMMARY where "KEY" = 'AplTaskElapsedTime';

-- Average time to train a segment  
select AVG(to_double("VALUE")) from DEBRIEF_SUMMARY where "KEY" = 'AplTaskElapsedTime';

-- Total time 
select * from DEBRIEF_SUMMARY where "KEY" = 'AplTotalElapsedTime';

-- Debrief all models by segment
select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::ClassificationRegression_Performance"(DEBRIEF_PROPERTY, DEBRIEF_METRIC);
