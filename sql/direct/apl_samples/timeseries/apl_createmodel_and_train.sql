-- ================================================================
-- APL_AREA, CREATE_MODEL_AND_TRAIN, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).


-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

-- Input table type: dataset
drop type CASHFLOWS_T;
create type CASHFLOWS_T as table (
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
-- Create a view which contains the sorted dataset
-- --------------------------------------------------------------------------

drop view CASHFLOWS_SORTED;
create view CASHFLOWS_SORTED as select * from "APL_SAMPLES"."CASHFLOWS" order by "Date" asc;


-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------

-- the AFL wrapper generator needs the signature of the expected stored proc
drop table CREATE_MODEL_AND_TRAIN_SIGNATURE;
create column table CREATE_MODEL_AND_TRAIN_SIGNATURE   like PROCEDURE_SIGNATURE_T;

insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_T', 'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_T', 'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (5, 'USER_APL','CASHFLOWS_T', 'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (6, 'USER_APL','MODEL_BIN_OID_T', 'OUT');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (7, 'USER_APL','OPERATION_LOG_T', 'OUT');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (8, 'USER_APL','SUMMARY_T', 'OUT');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (9, 'USER_APL','INDICATORS_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_CREATE_MODEL_AND_TRAIN');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','CREATE_MODEL_AND_TRAIN','USER_APL', 'APLWRAPPER_CREATE_MODEL_AND_TRAIN', CREATE_MODEL_AND_TRAIN_SIGNATURE);



-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table CREATE_AND_TRAIN_CONFIG;
create table CREATE_AND_TRAIN_CONFIG like OPERATION_CONFIG_T;
insert into CREATE_AND_TRAIN_CONFIG values ('APL/ModelType', 'timeseries');
insert into CREATE_AND_TRAIN_CONFIG values ('APL/TimePointColumnName', 'Date');
insert into CREATE_AND_TRAIN_CONFIG values ('APL/Horizon', '21');

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_T;
insert into VARIABLE_ROLES values ('Last4WDays', 'skip');
insert into VARIABLE_ROLES values ('Last5WDaysInd', 'skip');
insert into VARIABLE_ROLES values ('BeforeLastThursday', 'skip');
insert into VARIABLE_ROLES values ('Last4WDaysInd', 'skip');
insert into VARIABLE_ROLES values ('WorkingDaysIndices', 'skip');
insert into VARIABLE_ROLES values ('LastThursday', 'skip');
insert into VARIABLE_ROLES values ('BeforeLastFriday', 'skip');
insert into VARIABLE_ROLES values ('Last5WDays', 'skip');
insert into VARIABLE_ROLES values ('BeforeLastWednesday', 'skip');
insert into VARIABLE_ROLES values ('ReverseWorkingDaysIndices', 'skip');
insert into VARIABLE_ROLES values ('BeforeLastTuesday', 'skip');
insert into VARIABLE_ROLES values ('LastTuesday', 'skip');
insert into VARIABLE_ROLES values ('ThursdayMonthInd', 'skip');
insert into VARIABLE_ROLES values ('FridayMonthInd', 'skip');
insert into VARIABLE_ROLES values ('LastMonday', 'skip');
insert into VARIABLE_ROLES values ('LastWednesday', 'skip');
insert into VARIABLE_ROLES values ('BeforeLastWMonth', 'skip');
insert into VARIABLE_ROLES values ('WednesdayMonthInd', 'skip');
insert into VARIABLE_ROLES values ('LastFriday', 'skip');
insert into VARIABLE_ROLES values ('BeforeLastMonday', 'skip');
insert into VARIABLE_ROLES values ('TuesdayMonthInd', 'skip');
insert into VARIABLE_ROLES values ('MondayMonthInd', 'skip');
insert into VARIABLE_ROLES values ('LastWMonth', 'skip');
insert into VARIABLE_ROLES values ('Date', 'input');
insert into VARIABLE_ROLES values ('Cash', 'target');

drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like MODEL_BIN_OID_T;

drop table OPERATION_LOG;
create table OPERATION_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

drop table CASHFLOWS_DESC;
create table CASHFLOWS_DESC like VARIABLE_DESC_T;
insert into CASHFLOWS_DESC  select * from APL_SAMPLES.CASHFLOWS_DESC;
select * from "USER_APL"."CASHFLOWS_DESC";


-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from CREATE_AND_TRAIN_CONFIG;            
    var_desc = select * from CASHFLOWS_DESC;              
    var_role = select * from VARIABLE_ROLES;  
    dataset  = select * from CASHFLOWS_SORTED;  

    APLWRAPPER_CREATE_MODEL_AND_TRAIN(:header, :config, :var_desc,:var_role, :dataset,out_model,out_log,out_sum,out_indic);
    
    -- store result into table
    insert into  "USER_APL"."MODEL_TRAIN_BIN" select * from :out_model;
    insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;
    insert into  "USER_APL"."SUMMARY"         select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"      select * from :out_indic;

	-- show result
	select * from :out_model;
	select * from :out_log;
	select * from :out_sum;
	select * from :out_indic;
END;
