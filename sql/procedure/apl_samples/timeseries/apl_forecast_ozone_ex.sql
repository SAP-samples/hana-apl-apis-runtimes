-- ================================================================
-- APL_AREA, FORECAST
-- Description :
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';


-- --------------------------------------------------------------------------
-- Create table type for the forecast output
-- --------------------------------------------------------------------------

drop type OZONE_FORECAST_OUT_T;
create type OZONE_FORECAST_OUT_T as table (
	"Date" DAYDATE,
	"OzoneRateLA" DOUBLE,
	"kts_1" DOUBLE,
	"kts_1_lowerlimit_95%" DOUBLE,
    "kts_1_upperlimit_95%" DOUBLE
);
-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');

-- Create a view which contains the sorted dataset
drop view OZONE_RATE_LA_SORTED;
create view OZONE_RATE_LA_SORTED as select * from APL_SAMPLES.OZONE_RATE_LA order by "Date" asc;

drop table FORECAST_CONFIG;
create table FORECAST_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into FORECAST_CONFIG values ('APL/Horizon', '12',null);
insert into FORECAST_CONFIG values ('APL/TimePointColumnName', 'Date',null);
insert into FORECAST_CONFIG values ('APL/ForcePositiveForecast', 'true',null);
insert into FORECAST_CONFIG values ('APL/ApplyExtraMode','Forecasts and Error Bars', null);


drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- let this table empty to use guess variables

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
insert into VARIABLE_ROLES values ('Date', 'input',NULL,NULL,'#42');
insert into VARIABLE_ROLES values ('OzoneRateLA', 'target',NULL,NULL,'#42');

drop table FORECAST_OUT;
create table FORECAST_OUT like OZONE_FORECAST_OUT_T;

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    config    = select * from FORECAST_CONFIG;    
	var_desc = select * from VARIABLE_DESC;              
	var_role = select * from VARIABLE_ROLES;  
      

    "SAP_PA_APL"."sap.pa.apl.base::FORECAST"(:header,  :config, :var_desc, :var_role,'USER_APL','OZONE_RATE_LA_SORTED', 'USER_APL','FORECAST_OUT', out_log, out_summary, out_indicators);
    
    -- store result into table
    insert into  "USER_APL"."OPERATION_LOG"    select * from :out_log;
    insert into  "USER_APL"."SUMMARY"          select * from :out_summary;
	insert into  "USER_APL"."INDICATORS"       select * from :out_indicators;

	-- show result
	select * from "USER_APL"."FORECAST_OUT" order by "Date" asc;
	select * from "USER_APL"."OPERATION_LOG";
	select * from "USER_APL"."SUMMARY";
	select * from "USER_APL"."INDICATORS";
END;
