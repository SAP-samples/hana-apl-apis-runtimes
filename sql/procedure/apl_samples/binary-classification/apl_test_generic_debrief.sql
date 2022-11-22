-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

DO BEGIN
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare test_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare debrief_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";      
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      
    declare out_model "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";
    declare out_model_test "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";
    declare out_log   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";      
    declare out_sum   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";      
    declare out_debrief_metric "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";      
    declare out_debrief_property "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";      

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '8'));
    :header.insert(('ModelFormat', 'bin'));

    :config.insert(('APL/ModelType', 'binary classification',null));
    :config.insert(('APL/MaxIterations', '100',null)); -- default value: 1000
    :config.insert(('APL/EarlyStoppingPatience', '10',null)); -- default value: 10
    :config.insert(('APL/LearningRate', '.08',null)); -- default value: 0.1
    :config.insert(('APL/CorrelationsMaxKept', '10',null)); -- default value: 1024
    :config.insert(('APL/CorrelationsLowerBound', '.99',null)); -- default value: 0.50
    :config.insert(('APL/EvalMetric', 'LogLoss,AUC',null));

    :config.insert(('APL/VariableAutoSelection', 'true',null));
    :config.insert(('APL/VariableSelectionPercentageOfContributionKeptByStep', '0.97',null)); -- default value: 0.95
    :config.insert(('APL/VariableSelectionQualityBar', '0.02',null)); -- default value: 0.01
    :config.insert(('APL/VariableSelectionMaxIterations', '4',null)); -- default value: 2

    :var_role.insert(('class', 'target', null, null, null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role, 'APL_SAMPLES','ADULT01',out_model,out_log,out_sum, out_indicators);
    "SAP_PA_APL"."sap.pa.apl.base::TEST_MODEL"(:header, :out_model, :test_config,'APL_SAMPLES','ADULT01', out_model_test, out_log, out_indicators);
	"SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_DEBRIEF"(:header, :out_model_test, :debrief_config, out_debrief_metric, out_debrief_property, out_debrief_summary);

    -- Dump Statistics Report
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_Partition"(:out_debrief_property, :out_debrief_metric);

    -- Dump Statistics Binary Target
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::BinaryTarget_CurveRoc"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::BinaryTarget_CurveLift"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::BinaryTarget_CurveGain"(:out_debrief_property, :out_debrief_metric);
END;
