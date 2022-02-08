-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
-- COMPUTE_CONFUSION_MATRIX, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model with target 'class' (created by APL procedure call) an in the MODEL_TRAIN_BIN table.
--  @depend(apl_createmodel_and_train_ex.sql)

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');

drop table OPERATION_CONFIG;
create table OPERATION_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into OPERATION_CONFIG values ('APL/IndicatorDataset', 'Validation',null); -- Ask to export Indicator from  dataset 'Validation'

-- --------------------------------------------------------------------------
-- Extract Indicators from trained model 
-- --------------------------------------------------------------------------
DO BEGIN 
    declare config_matrix  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    header    = select * from FUNC_HEADER;       
    modle_in  = select * from MODEL_TRAIN_BIN;             
    config    = select * from OPERATION_CONFIG;          

    "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_INFO"(:header, :modle_in, :config, out_summary, out_variable_roles, out_variable_desc, out_indicators, out_profitcurves);
    
    -- store result into table
	insert into  "USER_APL"."INDICATORS" select * from :out_indicators;

	-- show result
    select * from "USER_APL"."INDICATORS";
 
    -- test default config
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;

    -- test with 0% Population 
    :config_matrix.insert(('APL/ConfusionMatrixFromPercentPopulation', '0',null));
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;
    
    -- test with 50% Population
    :config_matrix.delete();
    :config_matrix.insert(('APL/ConfusionMatrixFromPercentPopulation', '0.5',null));
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;
    
    -- test with 100% Population
    :config_matrix.delete();
    :config_matrix.insert(('APL/ConfusionMatrixFromPercentPopulation', '1',null));
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;

    -- test with 0% Target Key  Population 
    :config_matrix.delete();
    :config_matrix.insert(('APL/ConfusionMatrixFromPercentTargetKey', '0',null));
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;
    
    -- test with 50% Target Key Population
    :config_matrix.delete();
    :config_matrix.insert(('APL/ConfusionMatrixFromPercentTargetKey', '0.5',null));
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;

    -- test with 100% Target Key Population
    :config_matrix.delete();
    :config_matrix.insert(('APL/ConfusionMatrixFromPercentTargetKey', '1',null));
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;

    -- test with threshold 0.05
    :config_matrix.delete();
    :config_matrix.insert(('APL/ConfusionMatrixThreshold', '0.05',null));
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;

    -- test with threshold 0.10
    :config_matrix.delete();
    :config_matrix.insert(('APL/ConfusionMatrixThreshold', '0.10',null));
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;

    -- test with target class
    :config_matrix.delete();
    :config_matrix.insert(('APL/ConfusionMatrixTarget', 'class',null));
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;

    -- test with over max  threshold
    :config_matrix.delete();
    :config_matrix.insert(('APL/ConfusionMatrixThreshold', '2',null)); -- over max  threshold
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;

    -- test with  below min  threshold
    :config_matrix.delete();
    :config_matrix.insert(('APL/ConfusionMatrixThreshold', '-1',null)); -- below min  threshold
    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX"(:header,:config_matrix,:out_indicators, out_result);
    select * from :out_result;
    
    
END;
