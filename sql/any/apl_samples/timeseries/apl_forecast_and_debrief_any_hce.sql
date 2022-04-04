-- @required(hanaMinimumVersion,4.00.000)
-- Supported only on HANA Cloud
-- ================================================================
-- APL_AREA, FORECAST
-- Description :
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';


-- --------------------------------------------------------------------------
-- Create table type for the forecast output
-- --------------------------------------------------------------------------

drop type FORECAST_OUT_T;
create type FORECAST_OUT_T as table (
	"Date" DAYDATE,
	"Cash" DOUBLE,
	"kts_1" DOUBLE
);
-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');

-- Create a view which contains the sorted dataset
drop view CASHFLOWS_SORTED;
create view CASHFLOWS_SORTED as select 
"Date",
to_integer("WorkingDaysIndices") as "WorkingDaysIndices",
to_integer("ReverseWorkingDaysIndices") as "ReverseWorkingDaysIndices",
to_integer("MondayMonthInd") as "MondayMonthInd",
to_integer("TuesdayMonthInd") as "TuesdayMonthInd",
to_integer("WednesdayMonthInd") as "WednesdayMonthInd",
to_integer("ThursdayMonthInd") as "ThursdayMonthInd",
to_integer("FridayMonthInd") as "FridayMonthInd",
to_integer("BeforeLastMonday") as "BeforeLastMonday",
to_integer("LastMonday") as "LastMonday",
to_integer("BeforeLastTuesday") as "BeforeLastTuesday" ,
to_integer("LastTuesday") as "LastTuesday",
to_integer("BeforeLastWednesday") as "BeforeLastWednesday",
to_integer("LastWednesday") as "LastWednesday",
to_integer("BeforeLastThursday") as "BeforeLastThursday",
to_integer("LastThursday") as "LastThursday",
to_integer("BeforeLastFriday") as "BeforeLastFriday",
to_integer("LastFriday") as "LastFriday",
to_integer("Last5WDaysInd") as "Last5WDaysInd",
to_integer("Last5WDays") as "Last5WDays",
to_integer("Last4WDaysInd") as "Last4WDaysInd",
to_integer("Last4WDays") as "Last4WDays",
to_integer("LastWMonth") as "LastWMonth",
to_integer("BeforeLastWMonth") as "BeforeLastWMonth",
"Cash"
 from "APL_SAMPLES"."CASHFLOWS_FULL" order by "Date" asc;

drop table FORECAST_CONFIG;
create table FORECAST_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into FORECAST_CONFIG values ('APL/Horizon', '20',null);
insert into FORECAST_CONFIG values ('APL/TimePointColumnName', 'Date',null);
insert into FORECAST_CONFIG values ('APL/LastTrainingTimePoint', '2001-12-29 00:00:00',null);
insert into FORECAST_CONFIG values ('APL/ForcePositiveForecast', 'true',null);
insert into FORECAST_CONFIG values ('APL/WithExtraPredictable', 'true',null);
insert into FORECAST_CONFIG values ('APL/DebriefId', '10', null);

drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- let this table empty to use guess variables

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
insert into VARIABLE_ROLES values ('Date', 'input',NULL,NULL,'#42');
insert into VARIABLE_ROLES values ('Cash', 'target',NULL,NULL,'#42');

drop table FORECAST_OUT;
create table FORECAST_OUT like FORECAST_OUT_T;

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table DEBRIEF_METRIC;
create table DEBRIEF_METRIC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";

drop table DEBRIEF_PROPERTY;
create table DEBRIEF_PROPERTY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";

-- --------------------------------------------------------------------------
-- extra info from metric and property
-- --------------------------------------------------------------------------
drop view DEBRIEF_MODEL;
create view  DEBRIEF_MODEL  as (
SELECT "OID", "OWNER_ID" as "ID",
  MAX(CASE WHEN NAME='NAME' THEN "VALUE" ELSE NULL END) AS "NAME",
  MAX(CASE WHEN NAME='VERSION' THEN "VALUE" ELSE NULL END) AS "VERSION",
  MAX(CASE WHEN NAME='AUTHOR' THEN "VALUE" ELSE NULL END) AS "AUTHOR",
  MAX(CASE WHEN NAME='BUILD_DATE' THEN "VALUE" ELSE NULL END) AS "BUILD_DATE",
  MAX(CASE WHEN NAME='CUTTING' THEN "VALUE" ELSE NULL END) AS "CUTTING"
FROM "USER_APL"."DEBRIEF_PROPERTY"  WHERE "OWNER_TYPE" = 'MODEL'  and  "NAME" in  ('NAME','VERSION', 'AUTHOR','BUILD_DATE','CUTTING' ) GROUP BY "OWNER_ID", "OID" );


drop view DEBRIEF_DATASET;
create view  DEBRIEF_DATASET  as (
SELECT "OID", "OWNER_ID" as "ID",
  MAX(CASE WHEN NAME='NAME' THEN "VALUE" ELSE NULL END) AS "NAME",
  MAX(CASE WHEN NAME='STORE_NAME' THEN "VALUE" ELSE NULL END) AS "STORE_NAME",
  MAX(CASE WHEN NAME='STORE_SPACE' THEN TO_NVARCHAR("LONG_VALUE") ELSE NULL END) AS "STORE_SPACE",
  MAX(CASE WHEN NAME='FILTER_CONDITION' THEN TO_NVARCHAR("LONG_VALUE") ELSE NULL END) AS "FILTER_CONDITION",
  MAX(CASE WHEN NAME='NB_RECORDS' THEN "D_VALUE" ELSE NULL END) AS "NB_RECORDS",
  MAX(CASE WHEN NAME='TOTAL_WEIGHT' THEN "D_VALUE" ELSE NULL END) AS "TOTAL_WEIGHT"
FROM "USER_APL"."DEBRIEF_PROPERTY"  WHERE "OWNER_TYPE" = 'DATASET'  and  "NAME" in  ('NAME','STORE_NAME', 'STORE_SPACE','FILTER_CONDITION','NB_RECORDS', 'TOTAL_WEIGHT' ) GROUP BY "OWNER_ID", "OID" );

drop view DEBRIEF_VARIABLE;
create view  DEBRIEF_VARIABLE  as (
SELECT "OID",  "OWNER_ID" as "ID",
  MAX(CASE WHEN NAME='NAME' THEN "VALUE" ELSE NULL END) AS "NAME",
  MAX(CASE WHEN NAME='VALUE_TYPE' THEN "VALUE" ELSE NULL END) AS "VALUE_TYPE",
  MAX(CASE WHEN NAME='SOTRAGE_TYPE' THEN "VALUE" ELSE NULL END) AS "SOTRAGE_TYPE",
  MAX(CASE WHEN NAME='ROLE' THEN "VALUE" ELSE NULL END) AS "ROLE",
  MAX(CASE WHEN NAME='KEY_LEVEL' THEN "VALUE" ELSE NULL END) AS "KEY_LEVEL",
  MAX(CASE WHEN NAME='ORDER_LEVEL' THEN "VALUE" ELSE NULL END) AS "ORDER_LEVEL",
  MAX(CASE WHEN NAME='MISSING_STRING' THEN "VALUE" ELSE NULL END) AS "MISSING_STRING",  
  MAX(CASE WHEN NAME='DESCRIPTION' THEN "VALUE" ELSE NULL END) AS "DESCRIPTION",
  MAX(CASE WHEN NAME='TARGET_KEY' THEN "VALUE" ELSE NULL END) AS "TARGET_KEY",
  MAX(CASE WHEN NAME='ESTIMATOR_OF' THEN "I_VALUE" ELSE NULL END) AS "ESTIMATOR_OF"
FROM "USER_APL"."DEBRIEF_PROPERTY"  WHERE "OWNER_TYPE" = 'VARIABLE'  and  "NAME" in  ('NAME','VALUE_TYPE', 'SOTRAGE_TYPE','ROLE','KEY_LEVEL','ORDER_LEVEL','MISSING_STRING','DESCRIPTION','TARGET_KEY','ESTIMATOR_OF' ) GROUP BY "OWNER_ID", "OID" );


-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN
	declare out_forecast FORECAST_OUT_T;
	declare out_log "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";
	declare out_summary "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";
	declare out_indicators "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";
	declare out_debrief_metric "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";
	declare out_debrief_property "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";



  header   = select * from FUNC_HEADER;       
  config   = select * from FORECAST_CONFIG;    
	var_desc = select * from VARIABLE_DESC;              
	var_role = select * from VARIABLE_ROLES;  
	dataset  = select * from USER_APL.CASHFLOWS_SORTED;  
      

  "_SYS_AFL"."APL_FORECAST__OVERLOAD_5_6"(:header,  :config, :var_desc, :var_role, :dataset, out_forecast, out_log, out_summary, out_indicators, out_debrief_metric,out_debrief_property);
    
    -- store result into table
	insert into  "USER_APL"."FORECAST_OUT"     select * from :out_forecast;
  insert into  "USER_APL"."OPERATION_LOG"    select * from :out_log;
  insert into  "USER_APL"."SUMMARY"          select * from :out_summary;
	insert into  "USER_APL"."INDICATORS"       select * from :out_indicators;
  insert into  "USER_APL"."DEBRIEF_METRIC"   select * from :out_debrief_metric;
  insert into  "USER_APL"."DEBRIEF_PROPERTY" select * from :out_debrief_property;

	-- show result
	select * from "USER_APL"."FORECAST_OUT" order by "Date" asc;
	select * from "USER_APL"."OPERATION_LOG";
	select * from "USER_APL"."SUMMARY";
	select * from "USER_APL"."INDICATORS";
	select * from DEBRIEF_MODEL; 
	select * from DEBRIEF_DATASET;
	select * from DEBRIEF_VARIABLE;
END;
