-- @required(hanaMinimumVersion,2.0.40)
-- ================================================================
connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table DEBRIEF_METRIC;
create table DEBRIEF_METRIC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";

drop table DEBRIEF_PROPERTY;
create table DEBRIEF_PROPERTY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";

drop table ADULT01_SEG;
create table ADULT01_SEG as (select *, 1 as "Seg" from "APL_SAMPLES"."ADULT01");

drop view ADULT01_SORTED;
create view ADULT01_SORTED as select * from "ADULT01_SEG" order by "Seg"asc;

drop procedure "adult01_fill_segmented_dataset";
create procedure "adult01_fill_segmented_dataset"(in nb_seg integer )
as BEGIN 
	declare i integer;
    truncate table "ADULT01_SEG";
   
    -- insert segment with not enough values to trigger an error
    insert into "ADULT01_SEG" select  *,  -1 as "Seg" from "APL_SAMPLES"."ADULT01"  limit 1;
   
   	-- insert n segments  
	for i in 1..:nb_seg do 
       insert into "ADULT01_SEG" select  *,  :i as "Seg" from "APL_SAMPLES"."ADULT01";
	end for;
END;

call  "adult01_fill_segmented_dataset"(2);


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
    :header.insert(('LogLevel', '2'));
    :header.insert(('ModelFormat', 'bin'));
    :header.insert(('CheckOperationConfig', 'true'));
    :header.insert(('MaxTasks', '2'));  -- define nb parallel tasks to use for train

    :config.insert(('APL/SegmentColumnName', 'Seg',null)); -- define the column used as the segmentation colum
    :config.insert(('APL/ModelType', 'clustering',null));

    :var_role.insert(('class', 'skip',null,null,null));
    :var_role.insert(('fnlwgt', 'target',null,null,null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN_DEBRIEF"(:header, :config, :var_desc,:var_role, 'USER_APL','ADULT01_SORTED',out_model,out_log,out_sum,out_debrief_metric,out_debrief_property);

    -- store result into table
    insert into  MODEL_TRAIN_BIN  select * from :out_model;
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

-- Retrieve segment in error 
select * from OPERATION_LOG where "LEVEL" = 0;

-- Debrief all models by segment
select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_Partition"(DEBRIEF_PROPERTY, DEBRIEF_METRIC);
