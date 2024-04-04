-- @required(hanaMinimumVersion,2.0.40)
-- ================================================================
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';
drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop view DATASET_1;
create view DATASET_1 as select * from "APL_SAMPLES"."CENSUS" order by "sex", "id";

drop view DATASET_2;
create view DATASET_2 as select * from "APL_SAMPLES"."CENSUS" where "age" < 55 order by "sex", "id";
 
drop table PSEUDO_MODEL;
create table PSEUDO_MODEL like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table DEBRIEF_METRIC;
create table DEBRIEF_METRIC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";

drop table DEBRIEF_PROPERTY;
create table DEBRIEF_PROPERTY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";

DO BEGIN
    declare header_train   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare header_test    "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config_train   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED"; 
    declare config_test    "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED"; 
    declare debrief_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";      
    declare var_desc       "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role       "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      
    declare out_model_1    "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";      
    declare out_model_2    "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";      
    declare out_log        "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";      
    declare out_sum        "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";      
    declare out_debrief_metric "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";      
    declare out_debrief_property "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";
    declare out_indic "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";        

    :header_train.insert(('Oid', 'train stat Mdl'));
    :header_train.insert(('LogLevel', '8'));
    :header_train.insert(('CheckOperationConfig', 'true'));
    :header_train.insert(('MaxTasks', '2'));  -- define nb parallel tasks to use for train

    :header_test.insert(('Oid', 'test stat Mdl'));
    :header_test.insert(('LogLevel', '8'));
    :header_test.insert(('CheckOperationConfig', 'true'));
    :header_test.insert(('MaxTasks', '2'));  -- define nb parallel tasks to use for train    
    
    :config_train.insert(('APL/SegmentColumnName', 'sex',null)); -- define the column used as the segmentation colum
    :config_train.insert(('APL/ModelType', 'statbuilder',null));
    :config_test.insert(('APL/SegmentColumnName', 'sex',null)); -- define the column used as the segmentation colum

    :var_role.insert(('id', 'skip', null, null, null));
	:var_role.insert(('class', 'target', null, null, null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header_train, :config_train, :var_desc, :var_role, 'USER_APL','DATASET_1', 
	out_model_1, out_log, out_sum, out_indic);
    -- store result into table
    insert into  OPERATION_LOG    select * from :out_log;
    insert into  SUMMARY          select * from :out_sum;

	"SAP_PA_APL"."sap.pa.apl.base::TEST_MODEL_DEBRIEF" (:header_test, :out_model_1, :config_test, 'USER_APL','DATASET_2', 
	out_model_2, out_log, out_sum, out_debrief_metric, out_debrief_property);

    -- store result into table
    insert into  PSEUDO_MODEL     select * from :out_model_2;
    insert into  OPERATION_LOG    select * from :out_log;
    insert into  SUMMARY          select * from :out_sum;
    insert into  DEBRIEF_PROPERTY select * from :out_debrief_property;
    insert into  DEBRIEF_METRIC   select * from :out_debrief_metric;
END;

-- Nb trained models   
select count(*) from "USER_APL"."SUMMARY" where "KEY" = 'AplTaskElapsedTime';

-- Average time to train a segment  
select AVG(to_double("VALUE")) from SUMMARY where "KEY" = 'AplTaskElapsedTime';

-- Total time 
select * from SUMMARY where "KEY" = 'AplTotalElapsedTime';

-- Retrieve models in error 
select * from OPERATION_LOG where "LEVEL" = 0;

-- Debrief all models by segment
select * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_Partition"(USER_APL.DEBRIEF_PROPERTY, USER_APL.DEBRIEF_METRIC);
select * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_Variables"(USER_APL.DEBRIEF_PROPERTY, USER_APL.DEBRIEF_METRIC);
select * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_CategoryFrequencies"(USER_APL.DEBRIEF_PROPERTY, USER_APL.DEBRIEF_METRIC);
select * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_ContinuousVariables"(USER_APL.DEBRIEF_PROPERTY, USER_APL.DEBRIEF_METRIC);
