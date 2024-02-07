-- @required(hanaMinimumVersion,2.0.40)
-- ================================================================
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

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

drop table "CASHFLOWS_SEG";
create table "CASHFLOWS_SEG" as (select *, 1 as "Seg" from "APL_SAMPLES"."ANY_CASHFLOWS_FULL");

drop view "CASHFLOWS_SORTED";
create view "CASHFLOWS_SORTED" as select * from "CASHFLOWS_SEG" order by "Seg" , "Date" asc;

drop procedure "timeseries_fill_segmented_dataset";
create procedure "timeseries_fill_segmented_dataset"(in nb_seg integer )
as BEGIN
	declare i integer;
    truncate table "CASHFLOWS_SEG";

    -- insert segment with not enough values to trigger an error
    insert into "CASHFLOWS_SEG" select  *,  -1 as "Seg" from "APL_SAMPLES"."CASHFLOWS_FULL"  limit 1;

   -- insert n segments  
	for i in 1..:nb_seg do 
	   insert into "CASHFLOWS_SEG" select  *,:i as "Seg" from "APL_SAMPLES"."CASHFLOWS_FULL";
	end for;
END;

call "timeseries_fill_segmented_dataset"(2);

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
    :config.insert(('APL/ModelType', 'timeseries',null));
    :config.insert(('APL/Horizon','24',null));
    :config.insert(('APL/TimePointColumnName', 'Date',null));
    :config.insert(('APL/LastTrainingTimePoint', '2001-12-29 00:00:00',null));
    :config.insert(('APL/ActivateExplanations', 'true',null));
    :config.insert(('APL/DecomposeInfluencers', 'true',null));

    :var_role.insert(('Date', 'input', null, null, null));
    :var_role.insert(('Cash', 'target', null, null, null));

    :var_desc.insert((0,'Date','datetime','continuous',1,1,null,null,'Unique Id',null));
    :var_desc.insert((1,'Cash','number','continuous',0,0,null,null,null,null));
    :var_desc.insert((2,'MondayMonthInd','integer','ordinal',0,0,null,null,null,null));
    :var_desc.insert((3,'FridayMonthInd','integer','ordinal',0,0,null,null,null,null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN_DEBRIEF"(:header, :config, :var_desc,:var_role, 'USER_APL','CASHFLOWS_SORTED',out_model,out_log,out_sum,out_debrief_metric,out_debrief_property);

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
select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_Performance"(DEBRIEF_PROPERTY, DEBRIEF_METRIC);
