-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';
drop procedure "drop_table_if_exit";
create procedure  "drop_table_if_exit" (
 IN  in_schema    VARCHAR  (127),  -- Schema Name holding table to be dropped
 IN  in_table   VARCHAR  (127)    -- Table name to be dropped
)
LANGUAGE SQLSCRIPT
AS
BEGIN
  declare tab_exists smallint := 0;
  select count(*) into tab_exists from TABLES where schema_name = :in_schema and table_name = :in_table;
  
  IF tab_exists > 0 THEN
    exec 'drop table "' || :in_schema||'"."'||:in_table ||'"';
  END IF;
END;

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

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role,  'APL_SAMPLES','ADULT01',out_model,out_log,out_sum,out_indic);

    :apply_config.insert(('APL/ApplyExtraMode', 'Min Extra',null));   
    "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header, :out_model, :apply_config, 'APL_SAMPLES','ADULT01',out_schema, out_log);
   
    new_schema = SELECT OID, ROW_NUMBER() OVER ( ORDER BY POSITION ASC) AS "POSITION", NAME, KIND, "PRECISION", "SCALE", MAXIMUM_LENGTH FROM :out_schema;
    --new_schema = SELECT OID, ROW_NUMBER() OVER ( ORDER BY POSITION DESC) AS "POSITION", NAME, KIND, "PRECISION", "SCALE", MAXIMUM_LENGTH FROM :out_schema;
    "drop_table_if_exit"('USER_APL', 'APPLY_OUT_INVERT_ORDER');
      
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_TABLE_FROM_TABLE_TYPE"('USER_APL', 'APPLY_OUT_INVERT_ORDER', :new_schema);
    "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL"(:header,  :out_model,:apply_config, 'APL_SAMPLES','ADULT01', 'USER_APL', 'APPLY_OUT_INVERT_ORDER' , out_apply_log, out_sum);
END;

select * from "USER_APL"."APPLY_OUT_INVERT_ORDER";
