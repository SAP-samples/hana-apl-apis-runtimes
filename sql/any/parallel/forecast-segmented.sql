-- @required(hanaMinimumVersion,4.00.000)
-- Supported only on HANA Cloud
-- ================================================================
-- APL_AREA, FORECAST
-- Description :
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).
connect USER_APL password Password1;

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
create table "CASHFLOWS_SEG" as (select *, 1 as "Seg" from "APL_SAMPLES"."ANY_CASHFLOWS_FULL");
insert into "CASHFLOWS_SEG" select  *,2 as "Seg" from "APL_SAMPLES"."ANY_CASHFLOWS_FULL";
insert into "CASHFLOWS_SEG" select  *,3 as "Seg" from "APL_SAMPLES"."ANY_CASHFLOWS_FULL";
insert into "CASHFLOWS_SEG" select  *,4 as "Seg" from "APL_SAMPLES"."ANY_CASHFLOWS_FULL";

drop view "CASHFLOWS_SORTED";
create view "CASHFLOWS_SORTED" as select * from "CASHFLOWS_SEG" order by "Seg" , "Date" asc;

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
    declare out_apply    FORECAST_OUT_T;
   
    applyin = SELECT * from "USER_APL"."CASHFLOWS_SORTED";
   
    truncate table "USER_APL"."FORECAST_OUT";

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '1'));
    :header.insert(('ModelFormat', 'bin'));
    :header.insert(('CheckOperationConfig', 'true'));
--    :header.insert(('ProgressLog','true'));
--    :header.insert(('Cancelable','true'));   
    :header.insert(('MaxTasks', '2'));  -- define nb parallel tasks to use for forecast

    :config.insert(('APL/SegmentColumnName', 'Seg',null)); -- define the column used as the segmentation colum
    :config.insert(('APL/Horizon', '20',null));
    :config.insert(('APL/TimePointColumnName', 'Date',null));
    :config.insert(('APL/LastTrainingTimePoint', '2001-12-29 00:00:00',null));
    :config.insert(('APL/ForcePositiveForecast', 'true',null));
    :config.insert(('APL/WithExtraPredictable', 'true',null));

    :var_role.insert(('Date', 'input',null,null,'Daily Xtra'));
    :var_role.insert(('Cash', 'target',null,null,'Daily Xtra'));

    insert into :var_desc  select *, '#42' from APL_SAMPLES.CASHFLOWS_DESC;

    "_SYS_AFL"."APL_FORECAST__OVERLOAD_5_1"(:header,:config,:var_desc,:var_role,:applyin,out_apply);
    insert into  "USER_APL"."FORECAST_OUT"           select * from :out_apply;

END;

select count(*) from "USER_APL"."FORECAST_OUT";

