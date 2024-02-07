-- @required(hanaMinimumVersion,2.0.32)
connect USER_APL password Password1;

drop view CENSUS_SORTED;
create view CENSUS_SORTED as select "age", "workclass", "fnlwgt", "education", "education-num", "marital-status", "occupation", "relationship", "race", "sex", "capital-gain", "capital-loss", "hours-per-week", "native-country", "class" from APL_SAMPLES.CENSUS order by "id";


-- --------------------------------------------------------------------------
-- CREATE CLASSIFICATION AND REGRESSION MODEL AND TRAIN
-- --------------------------------------------------------------------------
drop table CLASSREG_MODEL_BIN_OUT;
create table CLASSREG_MODEL_BIN_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table CLASSREG_SCHEMA_OUT;
create table CLASSREG_SCHEMA_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.TABLE_TYPE";


DO BEGIN     
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare apply_config  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";      
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '8'));
    :header.insert(('ModelFormat', 'bin'));
    :header.insert(('CheckOperationConfig', 'true'));
          
    :config.insert(('APL/ModelType', 'regression/classification',null));
        
    :var_role.insert(('class', 'target', null, null, null));
    :var_role.insert(('age', 'target', null, null, null));

    :apply_config.insert(('APL/ApplyBar', 'true', 'class'));
    :apply_config.insert(('APL/ApplyBar', 'true', 'age'));
    :apply_config.insert(('APL/ApplyPredictedValue', 'true', 'class'));
    :apply_config.insert(('APL/ApplyPredictedValue', 'true', 'age'));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role, 'USER_APL', 'CENSUS_SORTED',out_model,out_log,out_sum,out_indic);
    "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header, :out_model, :apply_config, 'USER_APL', 'CENSUS_SORTED', out_schema ,out_log);

    -- store result into table
    insert into  "USER_APL"."CLASSREG_MODEL_BIN_OUT" select * from :out_model;
    insert into  "USER_APL"."CLASSREG_SCHEMA_OUT"    select * from :out_schema;

    select * from CLASSREG_SCHEMA_OUT order by POSITION;    


END;
