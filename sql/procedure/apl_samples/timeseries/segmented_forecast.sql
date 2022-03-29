-- @required(hanaMinimumVersion,2.0.40)
-- ================================================================
connect USER_APL password Password1;
set session 'APL_CACHE_SCHEMA' = 'APL_CACHE';

drop type FORECAST_OUT_T;
create type FORECAST_OUT_T as table (
    "Seg"  INTEGER,
	"Date" DAYDATE,
	"Cash" DOUBLE,
	"kts_1" DOUBLE
);

drop table FORECAST_OUT;
create table FORECAST_OUT like FORECAST_OUT_T;

drop table "CASHFLOWS_SEG";
create table "CASHFLOWS_SEG" as (select *, 1 as "Seg" from "APL_SAMPLES"."CASHFLOWS_FULL" limit 1);


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

call "timeseries_fill_segmented_dataset"(4);



drop view "CASHFLOWS_SORTED";
create view "CASHFLOWS_SORTED" as select * from "CASHFLOWS_SEG" order by "Seg" , "Date" asc;

drop table "FORECAST_SUMMARY";
create table "FORECAST_SUMMARY" like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table "FORECAST_INDICATORS";
create table "FORECAST_INDICATORS" like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table "FORECAST_DEBRIEF_METRIC";
create table "FORECAST_DEBRIEF_METRIC" like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";

drop table "FORECAST_DEBRIEF_PROPERTY";
create table "FORECAST_DEBRIEF_PROPERTY" like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";

drop table "FORECAST_LOG";
create table "FORECAST_LOG" like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

DO BEGIN
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      
    declare out_log   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";      
    declare out_sum   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";      
    declare out_indic "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";      
    declare out_debrief_metric "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";      
    declare out_debrief_property "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";
   
    truncate table "USER_APL"."FORECAST_SUMMARY";
    truncate table "USER_APL"."FORECAST_LOG";
    truncate table "USER_APL"."FORECAST_OUT";
    truncate table "USER_APL"."FORECAST_INDICATORS";
    truncate table "USER_APL"."FORECAST_DEBRIEF_METRIC";
    truncate table "USER_APL"."FORECAST_DEBRIEF_PROPERTY";

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '1'));
    :header.insert(('ModelFormat', 'bin'));
    :header.insert(('MaxTasks', '4'));  -- define nb parallel tasks to use for forecast

    :config.insert(('APL/SegmentColumnName', 'Seg',null)); -- define the column used as the segmentation colum
    :config.insert(('APL/Horizon', '20',null));
    :config.insert(('APL/TimePointColumnName', 'Date',null));
    :config.insert(('APL/LastTrainingTimePoint', '2001-12-29 00:00:00',null));
    :config.insert(('APL/ForcePositiveForecast', 'true',null));
    :config.insert(('APL/WithExtraPredictable', 'true',null));

    :var_role.insert(('Date', 'input',null,null,'Daily Xtra'));
    :var_role.insert(('Cash', 'target',null,null,'Daily Xtra'));

    insert into :var_desc  select *, '#42' from APL_SAMPLES.CASHFLOWS_DESC;

    "SAP_PA_APL"."sap.pa.apl.base::FORECAST_AND_DEBRIEF"(:header,:config,:var_desc,:var_role,'USER_APL','CASHFLOWS_SORTED', 'USER_APL','FORECAST_OUT',out_log,out_sum,out_indic,out_debrief_metric,out_debrief_property);

    insert into  "USER_APL"."FORECAST_SUMMARY"           select * from :out_sum;
    insert into  "USER_APL"."FORECAST_LOG"               select * from :out_log;
    insert into  "USER_APL"."FORECAST_INDICATORS"        select * from :out_indic;
    insert into  "USER_APL"."FORECAST_DEBRIEF_METRIC"    select * from :out_debrief_metric;
    insert into  "USER_APL"."FORECAST_DEBRIEF_PROPERTY"  select * from :out_debrief_property;
   
END;

select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_ModelOverview"("USER_APL"."FORECAST_DEBRIEF_PROPERTY",  "USER_APL"."FORECAST_DEBRIEF_METRIC");
