-- @required(hanaMinimumVersion,2.0.40)
-- ================================================================
-- APL_AREA, APPLY_MODEL, using a binary format for the model
-- This script demonstrates the application of the binary classification model
-- to predict the target and to get the individual contributions per input
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(segmented_create_train_reg.sql)
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

drop table TEST_INDICATORS;
create table TEST_INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

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
    declare out_indicators "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";      

    model = select * from MODEL_TRAIN_BIN;

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '2'));
    :header.insert(('CheckOperationConfig', 'true'));
    :header.insert(('MaxTasks', '2'));  -- define nb parallel tasks to use for train

    :config.insert(('APL/SegmentColumnName', 'Seg',null)); -- define the column used as the segmentation colum

    "SAP_PA_APL"."sap.pa.apl.base::TEST_MODEL"(:header, :model, :config,'USER_APL','ADULT01_SORTED', out_model, out_log, out_indicators);

    -- store result into table
    insert into  TEST_INDICATORS     select * from :out_indicators;
    insert into  TEST_MODEL_BIN      select * from :out_model;
    insert into  TEST_OPERATION_LOG  select * from :out_log;
END;

select * from  TEST_INDICATORS;
select * from  TEST_MODEL_BIN;
select * from  TEST_OPERATION_LOG;
