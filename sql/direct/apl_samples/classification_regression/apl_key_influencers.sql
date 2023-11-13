-- ================================================================
-- APL_AREA, KEY_INFLUENCERS
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
-- the AFL wrapper generator needs the signature of the expected stored proc
drop table KEY_INFLUENCERS_SIGNATURE;
create column table KEY_INFLUENCERS_SIGNATURE like PROCEDURE_SIGNATURE_T;
            
insert into KEY_INFLUENCERS_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into KEY_INFLUENCERS_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into KEY_INFLUENCERS_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_T', 'IN');
insert into KEY_INFLUENCERS_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_T', 'IN');
insert into KEY_INFLUENCERS_SIGNATURE values (5, 'USER_APL','ADULT01_T', 'IN');
insert into KEY_INFLUENCERS_SIGNATURE values (6, 'USER_APL','OPERATION_LOG_T', 'OUT');
insert into KEY_INFLUENCERS_SIGNATURE values (7, 'USER_APL','SUMMARY_T', 'OUT');
insert into KEY_INFLUENCERS_SIGNATURE values (8, 'USER_APL','INDICATORS_T', 'OUT');
insert into KEY_INFLUENCERS_SIGNATURE values (9, 'USER_APL','INFLUENCERS_T', 'OUT');
insert into KEY_INFLUENCERS_SIGNATURE values (10, 'USER_APL','CONTINUOUS_GROUPS_T', 'OUT');
insert into KEY_INFLUENCERS_SIGNATURE values (11, 'USER_APL','OTHER_GROUPS_T', 'OUT');
call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_KEY_INFLUENCERS');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','KEY_INFLUENCERS','USER_APL', 'APLWRAPPER_KEY_INFLUENCERS', KEY_INFLUENCERS_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

drop table KEY_INFLUENCERS_CONFIG;
create table KEY_INFLUENCERS_CONFIG like OPERATION_CONFIG_T;

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_T;
-- default roles are fine: all the variables but the last one are going to be input variables, the last one is the target

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
-- let this table empty to use guess variables

drop table INFLUENCERS;
create table INFLUENCERS like INFLUENCERS_T;

drop table CONTINUOUS_GROUPS;
create table CONTINUOUS_GROUPS like CONTINUOUS_GROUPS_T;

drop table OTHER_GROUPS;
create table OTHER_GROUPS like OTHER_GROUPS_T;

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
    config   = select * from KEY_INFLUENCERS_CONFIG;        
    var_desc = select * from VARIABLE_DESC;              
    var_role = select * from VARIABLE_ROLES;  
    dataset  = select * from APL_SAMPLES.ADULT01;  

    APLWRAPPER_KEY_INFLUENCERS(:header, :config, :var_desc,  :var_role, :dataset, out_log, out_sum,out_indic,out_influencer, out_continous_groups, out_other_groups);
    
    -- store result into table
	insert into  "USER_APL"."OPERATION_LOG"           select * from :out_log;
    insert into  "USER_APL"."SUMMARY"           select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"        select * from :out_indic;
    insert into  "USER_APL"."INFLUENCERS"       select * from :out_influencer;
    insert into  "USER_APL"."CONTINUOUS_GROUPS" select * from :out_continous_groups;
    insert into  "USER_APL"."OTHER_GROUPS"      select * from :out_other_groups;

	-- show result
	select * from "USER_APL"."OPERATION_LOG";
	select * from "USER_APL"."SUMMARY";
	select * from "USER_APL"."INDICATORS";
	select * from "USER_APL"."INFLUENCERS";
	select * from "USER_APL"."CONTINUOUS_GROUPS";
	select * from "USER_APL"."OTHER_GROUPS";
END;
