-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
-- COMPUTE_CONFUSION_MATRIX, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model with target 'class' (created by APL procedure call) an in the MODEL_TRAIN_BIN table.
--  @depend(apl_createmodel_and_train_ex.sql)

connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';    

-- --------------------------------------------------------------------------
-- Extract Indicators from trained model 
-- --------------------------------------------------------------------------
DO BEGIN 
    declare config_matrix  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_DETAILED";  
    declare config         "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_DETAILED"; 
    declare header         "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER"; 
    
    modle_in  = select * from MODEL_TRAIN_BIN;             
    
    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '8'));   
    :header.insert(('CheckOperationConfig', 'true'));
    
    -- get indicator for a model
    :config.insert(('APL/IndicatorDataset', 'Validation',null)); -- Ask to export Indicator from  dataset 'Validation'   
    "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_INFO"(:header, :modle_in, :config, out_summary, out_variable_roles, out_variable_desc, out_indicators, out_profitcurves);
    
    -- compute cost matrix with max profit
    :config_matrix.delete();
    :config_matrix.insert(('APL/ConfusionMatrixFromMaxProfit', 'true',null));
    :config_matrix.insert(('APL/TruePositiveCost', '2',null));
    :config_matrix.insert(('APL/TrueNegativeCost', '2',null));
    :config_matrix.insert(('APL/FalsePositiveCost', '-1',null));
    :config_matrix.insert(('APL/FalseNegativeCost', '-1',null));            
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;
    
    -- compute cost matrix with  a threshold  0.5
    :config_matrix.delete();
    :config_matrix.insert(('APL/ConfusionMatrixThreshold', '0.5',null));
    :config_matrix.insert(('APL/TruePositiveCost', '2',null));
    :config_matrix.insert(('APL/TrueNegativeCost', '2',null));
    :config_matrix.insert(('APL/FalsePositiveCost', '-1',null));
    :config_matrix.insert(('APL/FalseNegativeCost', '-1',null));            
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;   


    -- compute cost matrix with default value
    :config_matrix.delete();
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;       
END;
