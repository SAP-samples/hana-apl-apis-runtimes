-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
-- This scripts demonstrates how to create and train a Gradient
-- Boosting model for a binary classification task
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

DO BEGIN
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare apply_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";      
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '8'));
    :header.insert(('ModelFormat', 'bin'));
    :header.insert(('CheckOperationConfig', 'true'));

    :config.insert(('APL/ModelType', 'regression/classification',null));
    :config.insert(('APL/VariableAutoSelection', 'false',null));
    :config.insert(('APL/UsePhysicalNameForApply', 'true',null));
    :config.insert(('APL/UseTrainPhysicalNameBindingForApplyIn', 'true',null));

    :var_desc.insert((0, ' Logical age', 'integer', 'ordinal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((1, ' Logical workclass', 'string', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((2, ' Logical fnlwgt', 'integer', 'continuous', 0, 1, 'xxx', NULL, NULL, ''));
    :var_desc.insert((3, ' Logical education', 'string', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((4, ' Logical education-num', 'integer', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((5, ' Logical marital-status', 'string', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((6, ' Logical occupation', 'string', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((7, ' Logical relationship', 'string', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((8, ' Logical race', 'string', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((9, ' Logical sex', 'string', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((10, ' Logical capital-gain', 'integer', 'nominal', 0, 0, 'xxx',NULL, NULL, ''));
    :var_desc.insert((11, ' Logical capital-loss', 'integer', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((12, ' Logical hours-per-week', 'integer', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((13, ' Logical native-country', 'string', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((14, ' Logical class', 'integer', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));

    :var_role.insert((' Logical class', 'target', null, null, null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role,  'APL_SAMPLES','ADULT01',out_model,out_log,out_sum,out_indic);

    :apply_config.insert(('APL/ApplyExtraMode', 'Min Extra',null));
   
    "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header, :out_model, :apply_config, 'APL_SAMPLES','ADULT01',out_schema, out_log);
     
    SELECT * FROM :out_schema;
   
END;

