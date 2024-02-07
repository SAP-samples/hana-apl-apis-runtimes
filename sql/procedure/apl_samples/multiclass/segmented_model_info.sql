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
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table PROFITCURVES;
create table PROFITCURVES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.PROFITCURVE";


DO BEGIN     
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare model "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";      
    declare out_debrief_summary  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";      
    declare out_variable_roles   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      
    declare out_variable_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare out_indicators "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";      
    declare out_profitcurves "SAP_PA_APL"."sap.pa.apl.base::BASE.T.PROFITCURVE";      

	model = select * from MODEL_TRAIN_BIN;

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '2'));
    :header.insert(('CheckOperationConfig', 'true'));
    :header.insert(('MaxTasks', '2'));  -- define nb parallel tasks to use for train

    :config.insert(('APL/SegmentColumnName', 'Seg',null)); -- define the column used as the segmentation colum

    call "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_INFO"(:header, :model, :config, out_summary, out_variable_roles, out_variable_desc, out_indicators, out_profitcurves);
	
	-- store result into table
 	insert into  SUMMARY select * from :out_summary;
	insert into  VARIABLE_ROLES select * from :out_variable_roles;
	insert into  VARIABLE_DESC select * from :out_variable_desc;
	insert into  INDICATORS select * from :out_indicators;
	insert into  PROFITCURVES select * from :out_profitcurves;
END;

-- Nb trained models   
select count(*) from  SUMMARY where "KEY" = 'AplTaskElapsedTime';

-- Average time to train a segment  
select AVG(to_double("VALUE")) from SUMMARY where "KEY" = 'AplTaskElapsedTime';

-- Total time 
select * from SUMMARY where "KEY" = 'AplTotalElapsedTime';

select * from  VARIABLE_ROLES;
select * from  VARIABLE_DESC;
select * from  INDICATORS;
select * from  PROFITCURVES;
