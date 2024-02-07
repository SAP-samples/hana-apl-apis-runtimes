-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

DO BEGIN
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare debrief_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";      
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      
    declare out_model "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";      
    declare out_log   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";      
    declare out_sum   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";      
    declare out_debrief_metric "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";      
    declare out_debrief_property "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";      

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '8'));
    :header.insert(('ModelFormat', 'bin'));
    :header.insert(('CheckOperationConfig', 'true'));

    :config.insert(('APL/ModelType', 'regression/classification',null));
    :config.insert(('APL/VariableAutoSelection', 'true',null));

    :var_role.insert(('class', 'target', null, null, null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN_DEBRIEF"(:header, :config, :var_desc,:var_role, 'APL_SAMPLES','ADULT01',out_model,out_log,out_sum,out_debrief_metric,out_debrief_property);

    -- Dump Statistics Report
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_Partition"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_Variables"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_ContinuousVariables"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_CategoryFrequencies"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_GroupFrequencies"(:out_debrief_property, :out_debrief_metric);

    -- Dump Statistics Binary Target
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::BinaryTarget_Statistics"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::BinaryTarget_CrossStatistics"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::BinaryTarget_GroupCrossStatistics"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::BinaryTarget_CurveRoc"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::BinaryTarget_CurveLift"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::BinaryTarget_CurveGain"(:out_debrief_property, :out_debrief_metric);

    -- Dump Report
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::ClassificationRegression_VariablesExclusion"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::ClassificationRegression_VariablesSelectionDetails"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::ClassificationRegression_VariablesSelectionSummary"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::ClassificationRegression_VariablesSelectionPerformance"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::ClassificationRegression_VariablesCorrelation"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::ClassificationRegression_VariablesContribution"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::ClassificationRegression_Performance"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Classification_BinaryClass_ConfusionMatrix"(:out_debrief_property, :out_debrief_metric);
END;
