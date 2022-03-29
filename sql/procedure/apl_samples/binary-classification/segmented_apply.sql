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


DO BEGIN
    declare header  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
    declare model   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";
    declare out_log "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";
    declare out_sum "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

    insert into :model select * from MODEL_TRAIN_BIN;

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '2'));
    :header.insert(('ModelFormat', 'bin'));
    :header.insert(('MaxTasks', '4'));  -- define nb parallel tasks to use for train

    :config.insert(('APL/SegmentColumnName', 'Seg',null)); -- define the column used as the segmentation colum

    call "apl_apply_example_2"(:header, :model,  :config, 'USER_APL','ADULT01_SORTED', 'USER_APL','APPLY_OUT',out_log,out_sum);

    insert into  APPLY_OPERATION_LOG    select * from :out_log;
    insert into  APPLY_SUMMARY          select * from :out_sum;
END;

SELECT "Seg", count(*) from APPLY_OUT group by "Seg";

-- Nb trained models   
select count(*) from  APPLY_SUMMARY where "KEY" = 'AplTaskElapsedTime';

-- Average time to train a segment  
select AVG(to_double("VALUE")) from APPLY_SUMMARY where "KEY" = 'AplTaskElapsedTime';

-- Total time 
select * from APPLY_SUMMARY where "KEY" = 'AplTotalElapsedTime';

-- Get models in error
select * from APPLY_OPERATION_LOG where "LEVEL" = 0;
