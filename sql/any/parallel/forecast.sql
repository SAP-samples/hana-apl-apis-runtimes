-- @required(hanaMinimumVersion,2.0.30)
-- @required(hanaMaximumVersion,2.99.999)
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
	"Cash" DOUBLE
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



drop type OPERATION_CONFIG_P_T;
create type OPERATION_CONFIG_P_T as table (
    "group" VARCHAR(50),
    "KEY" VARCHAR(1000),
    "VALUE" VARCHAR(5000)
);

drop table FORECAST_CONFIG;
create table FORECAST_CONFIG like OPERATION_CONFIG_P_T;
insert into FORECAST_CONFIG values ('goup1','APL/Horizon', '21');
insert into FORECAST_CONFIG values ('goup1','APL/TimePointColumnName', 'Date');
insert into FORECAST_CONFIG values ('goup1','APL/LastTrainingTimePoint', '2001-12-29 00:00:00');
insert into FORECAST_CONFIG values ('goup2','APL/Horizon', '3');
insert into FORECAST_CONFIG values ('goup2','APL/TimePointColumnName', 'Date');
insert into FORECAST_CONFIG values ('goup2','APL/LastTrainingTimePoint', '2001-12-29 00:00:00');


drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- let this table empty to use guess variables

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
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
insert into VARIABLE_ROLES values ('Date', 'input',null,null,null);
insert into VARIABLE_ROLES values ('Cash', 'target',null,null,null);

drop table FORECAST_OUT;
create table FORECAST_OUT like FORECAST_OUT_T;

drop table FORECAST_OUT_P;
create table FORECAST_OUT_P (
    "group" VARCHAR(50),
	"Date" DAYDATE,
	"Cash" DOUBLE,
	"kts_1" DOUBLE
);

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";


-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
call "_SYS_AFL"."APL_FORECAST__OVERLOAD_5_1"(FUNC_HEADER, FORECAST_CONFIG, VARIABLE_DESC, VARIABLE_ROLES, USER_APL.CASHFLOWS_SORTED, FORECAST_OUT_P) with overview
  WITH HINT(PARALLEL_BY_PARAMETER_VALUES (p2."group"));

select *  from FORECAST_CONFIG;
select * from "USER_APL"."FORECAST_OUT_P" order by "Date" asc;


