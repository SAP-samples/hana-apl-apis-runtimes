-- @required(hanaMinimumVersion,2.0.32)
connect USER_APL password Password1;

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------

drop table MODEL_BIN_OUT;
create column table MODEL_BIN_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";     
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_roles "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";     
   
    :header.insert(('Oid', 'foobar'));
    :header.insert(('CheckOperationConfig', 'true'));
    :config.insert(('APL/ModelType', 'binary classification',null));
    :var_roles.insert(('class', 'target', null, null, null));
   
	call "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc, :var_roles, 'APL_SAMPLES', 'CENSUS', out_train_model, out_log, out_summary, out_indicators);
	
   -- store result into table
    insert into  "USER_APL"."MODEL_BIN_OUT"       select * from :out_train_model;
	
END;

-- APPLY EXTRA MODE PROBABILITY

drop table SCHEMA_OUT;
create table SCHEMA_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.TABLE_TYPE";

DO BEGIN     
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
	model = select * from MODEL_BIN_OUT;

    :header.insert(('Oid', 'foobar'));
    :header.insert(('CheckOperationConfig', 'true'));

    :config.insert(('APL/ApplyExtraMode', 'Advanced Apply Settings',null));   
    :config.insert(('APL/ApplyPredictedValue', 'true',null));   
   
	call "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header, :model, :config, 'APL_SAMPLES', 'CENSUS', out_schema , out_log);

   -- store result into table
    insert into  "USER_APL"."SCHEMA_OUT"       select * from :out_schema;
END;

