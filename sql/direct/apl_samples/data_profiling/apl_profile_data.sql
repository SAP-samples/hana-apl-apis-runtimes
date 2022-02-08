-- ================================================================
-- APL_AREA, PROFILE_DATA
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).


-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

-- Input table type: dataset
drop type ADULT01_T;
create type ADULT01_T as table (
	"age" INTEGER,
	"workclass" NVARCHAR(32),
	"fnlwgt" INTEGER,
	"education" NVARCHAR(32),
	"education-num" INTEGER,
	"marital-status" NVARCHAR(32),
	"occupation" NVARCHAR(32),
	"relationship" NVARCHAR(32),
	"race" NVARCHAR(32),
	"sex" NVARCHAR(16),
	"capital-gain" INTEGER,
	"capital-loss" INTEGER,
	"hours-per-week" INTEGER,
	"native-country" NVARCHAR(32),
	"class" INTEGER
);

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------

drop table PROFILE_DATA_SIGNATURE;
create column table PROFILE_DATA_SIGNATURE like PROCEDURE_SIGNATURE_T;
            
insert into PROFILE_DATA_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into PROFILE_DATA_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into PROFILE_DATA_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_T', 'IN');
insert into PROFILE_DATA_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_T', 'IN');
insert into PROFILE_DATA_SIGNATURE values (5, 'USER_APL','ADULT01_T', 'IN');
insert into PROFILE_DATA_SIGNATURE values (6, 'USER_APL','OPERATION_LOG_T', 'OUT');
insert into PROFILE_DATA_SIGNATURE values (7, 'USER_APL','SUMMARY_T', 'OUT');
insert into PROFILE_DATA_SIGNATURE values (8, 'USER_APL','INDICATORS_T', 'OUT');
insert into PROFILE_DATA_SIGNATURE values (9, 'USER_APL','VARIABLE_DESC_OID_T', 'OUT');
call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_PROFILE_DATA');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','PROFILE_DATA','USER_APL', 'APLWRAPPER_PROFILE_DATA', PROFILE_DATA_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');

drop table PROFILE_DATA_CONFIG;
create table PROFILE_DATA_CONFIG like OPERATION_CONFIG_T;

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_T;
-- default roles are adjusted: we want all variables to be considered as input variables when profiling the dataset.
insert into VARIABLE_ROLES values ('class', 'input');

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
-- let this table empty to let the engine guess variable descriptions

drop table OPERATION_LOG;
create table OPERATION_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

drop table VARIABLE_DESC_OUT;
create table VARIABLE_DESC_OUT like VARIABLE_DESC_OID_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from PROFILE_DATA_CONFIG;            
    var_desc = select * from VARIABLE_DESC;              
    var_role = select * from VARIABLE_ROLES;  
    dataset  = select * from APL_SAMPLES.ADULT01;  

    APLWRAPPER_PROFILE_DATA(:header, :config, :var_desc,:var_role, :dataset,out_log,out_sum,out_indic, out_var_desc);
    
    -- store result into table
    insert into  "USER_APL"."OPERATION_LOG"     select * from :out_log;
    insert into  "USER_APL"."SUMMARY"           select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"        select * from :out_indic;
	insert into  "USER_APL"."VARIABLE_DESC_OUT" select * from :out_var_desc;

	-- show result
	select * from "USER_APL"."OPERATION_LOG";
	select * from "USER_APL"."SUMMARY";
	select * from "USER_APL"."INDICATORS";
	select * from "USER_APL"."VARIABLE_DESC_OUT";
END;
