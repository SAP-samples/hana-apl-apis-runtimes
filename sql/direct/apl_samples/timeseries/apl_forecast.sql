-- ================================================================
-- APL_AREA, FORECAST
-- Description :
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).


-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

drop type CASHFLOWS_FULL_T;
create type CASHFLOWS_FULL_T as table (
	"Date" DAYDATE,
	"WorkingDaysIndices" INTEGER,
	"ReverseWorkingDaysIndices" INTEGER,
	"MondayMonthInd" INTEGER,
	"TuesdayMonthInd" INTEGER,
	"WednesdayMonthInd" INTEGER,
	"ThursdayMonthInd" INTEGER,
	"FridayMonthInd" INTEGER,
	"BeforeLastMonday" INTEGER,
	"LastMonday" INTEGER,
	"BeforeLastTuesday" INTEGER,
	"LastTuesday" INTEGER,
	"BeforeLastWednesday" INTEGER,
	"LastWednesday" INTEGER,
	"BeforeLastThursday" INTEGER,
	"LastThursday" INTEGER,
	"BeforeLastFriday" INTEGER,
	"LastFriday" INTEGER,
	"Last5WDaysInd" INTEGER,
	"Last5WDays" INTEGER,
	"Last4WDaysInd" INTEGER,
	"Last4WDays" INTEGER,
	"LastWMonth" INTEGER,
	"BeforeLastWMonth" INTEGER,
	"Cash" DECIMAL(17,6)
);

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
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
-- the AFL wrapper generator needs the signature of the expected stored proc
drop table FORECAST_SIGNATURE;
create column table FORECAST_SIGNATURE like PROCEDURE_SIGNATURE_T;

insert into FORECAST_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into FORECAST_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into FORECAST_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_T', 'IN');
insert into FORECAST_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_T', 'IN');
insert into FORECAST_SIGNATURE values (5, 'USER_APL','CASHFLOWS_FULL_T', 'IN');
insert into FORECAST_SIGNATURE values (6, 'USER_APL','FORECAST_OUT_T', 'OUT');
insert into FORECAST_SIGNATURE values (7, 'USER_APL','OPERATION_LOG_T', 'OUT');
insert into FORECAST_SIGNATURE values (8, 'USER_APL','SUMMARY_T', 'OUT');
insert into FORECAST_SIGNATURE values (9, 'USER_APL','INDICATORS_T', 'OUT');
call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_FORECAST');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','FORECAST','USER_APL', 'APLWRAPPER_FORECAST', FORECAST_SIGNATURE);


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');

-- Create a view which contains the sorted dataset
drop view CASHFLOWS_SORTED;
create view CASHFLOWS_SORTED as select * from APL_SAMPLES.CASHFLOWS_FULL order by "Date" asc;

drop table FORECAST_CONFIG;
create table FORECAST_CONFIG like OPERATION_CONFIG_T;
insert into FORECAST_CONFIG values ('APL/Horizon', '21');
insert into FORECAST_CONFIG values ('APL/TimePointColumnName', 'Date');
insert into FORECAST_CONFIG values ('APL/LastTrainingTimePoint', '2001-12-29 00:00:00');

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
-- let this table empty to use guess variables

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_T;
-- insert into VARIABLE_ROLES values ('Last4WDays', 'skip');
-- insert into VARIABLE_ROLES values ('Last5WDaysInd', 'skip');
-- insert into VARIABLE_ROLES values ('BeforeLastThursday', 'skip');
-- insert into VARIABLE_ROLES values ('Last4WDaysInd', 'skip');
-- insert into VARIABLE_ROLES values ('WorkingDaysIndices', 'skip');
-- insert into VARIABLE_ROLES values ('LastThursday', 'skip');
-- insert into VARIABLE_ROLES values ('BeforeLastFriday', 'skip');
-- insert into VARIABLE_ROLES values ('Last5WDays', 'skip');
-- insert into VARIABLE_ROLES values ('BeforeLastWednesday', 'skip');
-- insert into VARIABLE_ROLES values ('ReverseWorkingDaysIndices', 'skip');
-- insert into VARIABLE_ROLES values ('BeforeLastTuesday', 'skip');
-- insert into VARIABLE_ROLES values ('LastTuesday', 'skip');
-- insert into VARIABLE_ROLES values ('ThursdayMonthInd', 'skip');
-- insert into VARIABLE_ROLES values ('FridayMonthInd', 'skip');
-- insert into VARIABLE_ROLES values ('LastMonday', 'skip');
-- insert into VARIABLE_ROLES values ('LastWednesday', 'skip');
-- insert into VARIABLE_ROLES values ('BeforeLastWMonth', 'skip');
-- insert into VARIABLE_ROLES values ('WednesdayMonthInd', 'skip');
-- insert into VARIABLE_ROLES values ('LastFriday', 'skip');
-- insert into VARIABLE_ROLES values ('BeforeLastMonday', 'skip');
-- insert into VARIABLE_ROLES values ('TuesdayMonthInd', 'skip');
-- insert into VARIABLE_ROLES values ('MondayMonthInd', 'skip');
-- insert into VARIABLE_ROLES values ('LastWMonth', 'skip');
insert into VARIABLE_ROLES values ('Date', 'input');
insert into VARIABLE_ROLES values ('Cash', 'target');

drop table FORECAST_OUT;
create table FORECAST_OUT like FORECAST_OUT_T;

drop table OPERATION_LOG;
create table OPERATION_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    config    = select * from FORECAST_CONFIG;    
	var_desc = select * from VARIABLE_DESC;              
	var_role = select * from VARIABLE_ROLES;  
	dataset  = select * from USER_APL.CASHFLOWS_SORTED;  
      

    APLWRAPPER_FORECAST(:header,  :config, :var_desc, :var_role, :dataset, out_forecast, out_log, out_summary, out_indicators);
    
    -- store result into table
	insert into  "USER_APL"."FORECAST_OUT"     select * from :out_forecast;
    insert into  "USER_APL"."OPERATION_LOG"    select * from :out_log;
    insert into  "USER_APL"."SUMMARY"          select * from :out_summary;
	insert into  "USER_APL"."INDICATORS"       select * from :out_indicators;

	-- show result
	select * from "USER_APL"."FORECAST_OUT" order by "Date" asc;
	select * from "USER_APL"."OPERATION_LOG";
	select * from "USER_APL"."SUMMARY";
	select * from "USER_APL"."INDICATORS";
END;
