-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
-- @depend(apl_createmodel_and_train_ex.sql)

connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

DO BEGIN
	declare ERROR condition for SQL_ERROR_CODE 10001;
    declare count_1 integer;
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config_update "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    model_in         = select * from MODEL_TRAIN_BIN;

    :header.insert(('Oid', '#42'));
    :header.insert(('CheckOperationConfig', 'true'));

    :config_update.insert(('APL/ModelName', 'XXX-NEW-MODEL-NAME',null));

    "SAP_PA_APL"."sap.pa.apl.base::UPDATE_MODEL"(:header, :model_in, :config_update, :out_model);
    "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_INFO"(:header, :out_model, :config, out_summary, out_variable_roles, out_variable_desc, out_indicators, out_profitcurves);
    
    select count(*) into count_1 from :out_summary where KEY='ModelName' and VALUE='XXX-NEW-MODEL-NAME';
	if (count_1 = 0) then
	   signal ERROR set MESSAGE_TEXT = 'Change Model Name Failed';
	end if;    
END;
