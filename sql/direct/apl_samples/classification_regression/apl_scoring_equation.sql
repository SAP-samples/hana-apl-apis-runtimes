-- ================================================================
-- APL_AREA, SCORING_EQUATION using a binary format for the model
-- This script generates the scoring equation in SQL from an existing dataset
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).


-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

-- Input table type: dataset
drop type CENSUS_T;
create type CENSUS_T as table (
    "id" INTEGER,
	"age" INTEGER,
	"workclass" NVARCHAR(16),
	"fnlwgt" INTEGER,
	"education" NVARCHAR(12),
	"education-num" INTEGER,
	"marital-status" NVARCHAR(21),
	"occupation" NVARCHAR(17),
	"relationship" NVARCHAR(14),
	"race" NVARCHAR(18),
	"sex" NVARCHAR(6),
	"capital-gain" INTEGER,
	"capital-loss" INTEGER,
	"hours-per-week" INTEGER,
	"native-country" NVARCHAR(26),
	"class" INTEGER
);

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
-- the AFL wrapper generator needs the signature of the expected stored proc
drop table SCORING_EQUATION_SIGNATURE;
create column table SCORING_EQUATION_SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into SCORING_EQUATION_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into SCORING_EQUATION_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into SCORING_EQUATION_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_T', 'IN');
insert into SCORING_EQUATION_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_T', 'IN');
insert into SCORING_EQUATION_SIGNATURE values (5, 'USER_APL','CENSUS_T', 'IN');
insert into SCORING_EQUATION_SIGNATURE values (6, 'USER_APL','OPERATION_LOG_T', 'OUT');
insert into SCORING_EQUATION_SIGNATURE values (7, 'USER_APL','SUMMARY_T', 'OUT');
insert into SCORING_EQUATION_SIGNATURE values (8, 'USER_APL','INDICATORS_T', 'OUT');
insert into SCORING_EQUATION_SIGNATURE values (9, 'USER_APL','RESULT_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_SCORING_EQUATION');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','SCORING_EQUATION','USER_APL', 'APLWRAPPER_SCORING_EQUATION', SCORING_EQUATION_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table SCORING_EQUATION_CONFIG;
create table SCORING_EQUATION_CONFIG like OPERATION_CONFIG_T;
insert into SCORING_EQUATION_CONFIG values ('APL/CodeType', 'HANA');
insert into SCORING_EQUATION_CONFIG values ('APL/CodeTarget', 'class');
insert into SCORING_EQUATION_CONFIG values ('APL/CodeKey', '"id"');
insert into SCORING_EQUATION_CONFIG values ('APL/CodeSpace', 'APL_SAMPLES.CENSUS');
insert into SCORING_EQUATION_CONFIG values ('APL/ApplyExtraMode', 'No Extra');

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
-- let this table empty to make the engine guess the variable descriptions

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_T;
-- variable roles are optional, hence the empty table

drop table OPERATION_LOG;
create table OPERATION_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

drop table SCORING_EQUATION;
create table SCORING_EQUATION like RESULT_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    config   = select * from SCORING_EQUATION_CONFIG;
    var_desc = select * from VARIABLE_DESC;              
    var_role = select * from VARIABLE_ROLES;  
	dataset  = select * from APL_SAMPLES.CENSUS;  
	

    APLWRAPPER_SCORING_EQUATION(:header, :config, :var_desc, :var_role, :dataset,  out_log, out_sum, out_indic, out_equation);
    
    -- store result into table
    insert into  "USER_APL"."OPERATION_LOG"    select * from :out_log;
    insert into  "USER_APL"."SUMMARY"          select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"       select * from :out_indic;
    insert into  "USER_APL"."SCORING_EQUATION" select * from :out_equation;

	-- show result
	select * from "USER_APL"."OPERATION_LOG";
	select * from "USER_APL"."SUMMARY";
	select * from "USER_APL"."INDICATORS";
	select * from "USER_APL"."SCORING_EQUATION";
END;
