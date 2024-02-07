-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';
DO BEGIN
    declare INVALID_INPUT condition for SQL_ERROR_CODE 10001;
	declare count     integer;
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare no_meta_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";      
    declare with_meta_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";      
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      
    declare out_model "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";      
    declare out_log   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";      
    declare out_sum   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";      
    declare out_indic "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";      
    declare out_debrief_metric "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";      
    declare out_debrief_property "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";      

    :header.insert(('Oid', '#42'));

    :config.insert(('APL/ModelType', 'regression/classification',null));
   
    :var_role.insert(('class', 'target', null, null, null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role,  'APL_SAMPLES','ADULT01',out_model,out_log,out_sum,out_indic);    
    
    :with_meta_config.insert(('APL/DebriefMetadata', 'true',null));
    "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_DEBRIEF"(:header, :out_model, :with_meta_config, out_debrief_metric,out_debrief_property, out_sum);

    select count(*) into count from "SAP_PA_APL"."sap.pa.apl.debrief.internal.entity::DEBRIEF"(:out_debrief_property, :out_debrief_metric) where  "METADATA" is not null;
    if ( :count = 0 ) then
       signal INVALID_INPUT set MESSAGE_TEXT = 'METADATA field must not null';   
    end if;   
     

    :no_meta_config.insert(('APL/DebriefMetadata', 'false',null));
    "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_DEBRIEF"(:header, :out_model, :no_meta_config, out_debrief_metric,out_debrief_property, out_sum);

    select count(*) into count from "SAP_PA_APL"."sap.pa.apl.debrief.internal.entity::DEBRIEF"(:out_debrief_property, :out_debrief_metric) where  "METADATA" is null;
    if ( :count = 0 ) then
       signal INVALID_INPUT set MESSAGE_TEXT = 'METADATA field must null';   
    end if;   

END;
