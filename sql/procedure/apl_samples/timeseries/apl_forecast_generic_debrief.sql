-- @required(hanaMinimumVersion,2.0.40)
-- ================================================================
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

drop type FORECAST_OUT_T;
create type FORECAST_OUT_T as table (
	"Date" DAYDATE,
	"Cash" DOUBLE,
	"kts_1" DOUBLE
);

drop table FORECAST_OUT;
create table FORECAST_OUT like FORECAST_OUT_T;

drop view CASHFLOWS_SORTED;
create view CASHFLOWS_SORTED as select * from "APL_SAMPLES"."CASHFLOWS_FULL" order by "Date" asc;

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

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '8'));
    :header.insert(('ModelFormat', 'bin'));
    :header.insert(('CheckOperationConfig', 'true'));

    :config.insert(('APL/Horizon', '20',null));
    :config.insert(('APL/TimePointColumnName', 'Date',null));
    :config.insert(('APL/LastTrainingTimePoint', '2001-12-29 00:00:00',null));
    :config.insert(('APL/ForcePositiveForecast', 'true',null));
    :config.insert(('APL/WithExtraPredictable', 'true',null));
    :config.insert(('APL/ActivateExplanations', 'true',null));    

    :var_role.insert(('Date', 'input',null,null,'Daily Xtra'));
    :var_role.insert(('Cash', 'target',null,null,'Daily Xtra'));

    insert into :var_desc  select *, '#42' from APL_SAMPLES.CASHFLOWS_DESC;

    "SAP_PA_APL"."sap.pa.apl.base::FORECAST_AND_DEBRIEF"(:header,:config,:var_desc,:var_role,'USER_APL','CASHFLOWS_SORTED', 'USER_APL','FORECAST_OUT',out_log,out_sum,out_indic,out_debrief_metric,out_debrief_property);
 
    -- Dump Statistics Report
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_Partition"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_Variables"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_ContinuousVariables"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_CategoryFrequencies"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_GroupFrequencies"(:out_debrief_property, :out_debrief_metric);

    -- Dump Statistics Continuous Target
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::ContinuousTarget_Statistics"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::ContinuousTarget_CrossStatistics"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::ContinuousTarget_GroupCrossStatistics"(:out_debrief_property, :out_debrief_metric);

    -- Dump TimeSeries Report
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_ModelOverview"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_Components"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_DetrendedExtraPredictable"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_VariablesContribution"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_Performance"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_PerformanceByHorizon"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_Outliers"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_ImpactInfluencersCategorical"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_ImpactInfluencersNumerical"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_Decomposition"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_ChangePoints"(:out_debrief_property, :out_debrief_metric);
    select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::TimeSeries_ImpactCycles"(:out_debrief_property, :out_debrief_metric);
END;

