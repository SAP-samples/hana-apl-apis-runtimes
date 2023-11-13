-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
-- @depend(apl_apply_proc.sql)
connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

drop table "USER_APL"."APPLY_IN";
create TABLE "USER_APL"."APPLY_IN"  as (
SELECT  "native-country" as "country","class", "sex", "race",  "workclass", "education", "marital-status", "occupation", "relationship" , "age","hours-per-week",  "capital-loss","capital-gain", "fnlwgt", "education-num" FROM APL_SAMPLES.ADULT01 );
commit;

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

    -- Error 'APL/EnableMappingByPosForApply' is false -> wrong Mapping "native-country" is no find
    :config.insert(('APL/EnableMappingByPosForApply', 'true',null));

    :var_role.insert(('class', 'target', null, null, null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role,  'APL_SAMPLES','ADULT01',out_model,out_log,out_sum,out_indic);

    :apply_config.insert(('APL/ApplyExtraMode', 'Min Extra',null));
    "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header, :out_model, :apply_config, 'APL_SAMPLES','ADULT01',out_schema, out_log);
    "drop_table_if_exit"('USER_APL', 'APPLY_OUT');
      
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_TABLE_FROM_TABLE_TYPE"('USER_APL', 'APPLY_OUT', :out_schema);
    "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL"(:header,  :out_model,:apply_config, 'USER_APL','APPLY_IN', 'USER_APL', 'APPLY_OUT' , out_apply_log, out_sum);
END;

select * from "USER_APL"."APPLY_OUT";

