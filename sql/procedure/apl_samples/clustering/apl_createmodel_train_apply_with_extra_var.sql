-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
-- APL_AREA, CREATE_MODEL_AND_TRAIN, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

--SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table SCHEMA_OUT;
create table SCHEMA_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.TABLE_TYPE";

drop table SCHEMA_LOG;
create table SCHEMA_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
--------------------------------------------------------------------------
DO BEGIN     
   declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
   declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
   declare apply_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
   declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
   declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      

   :header.insert(('Oid', '#42'));
   :header.insert(('LogLevel', '8'));
   :header.insert(('ModelFormat', 'bin'));
   
   :config.insert (('APL/ModelType', 'clustering',null));
   :config.insert (('APL/CalculateSQLExpressions', 'false',null));
   :config.insert (('APL/NbClustersMin', '4',null));
   :config.insert (('APL/NbClustersMax', '5',null));
   :config.insert (('APL/Distance', 'SystemDetermined',null));

   :var_role.insert(('class', 'target', null, null, '#42'));
   :var_role.insert(('id', 'skip', null, null, '#42'));

   :apply_config.insert (('APL/ApplyExtraMode', 'Advanced Apply Settings', null));
   :apply_config.insert (('APL/ApplyCopyVariables','id;age;workclass;fnlwgt;education;education-num;marital-status;occupation;relationship;race;sex;capital-gain;capital-loss;hours-per-week;native-country;class', null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role, 'APL_SAMPLES','CENSUS',out_model,out_log,out_sum,out_indic);    
    "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header, :out_model, :apply_config, 'APL_SAMPLES','CENSUS', out_apply_type, out_apply_test_log);

    -- store result into table
    insert into  "USER_APL"."MODEL_TRAIN_BIN" select * from :out_model;
    insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;
    insert into  "USER_APL"."SUMMARY"         select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"      select * from :out_indic;
    insert into  "USER_APL"."SCHEMA_OUT"      select * from :out_apply_type;
    insert into  "USER_APL"."SCHEMA_LOG"      select * from :out_apply_test_log;

	-- show result
    select * from SCHEMA_OUT;
END;
