-- ================================================================
-- APL_AREA, KEY_INFLUENCERS
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(apl_createmodel_and_train.sql)

-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
-- the AFL wrapper generator needs the signature of the expected stored proc
drop table GET_KEY_INFLUENCERS_FROM_MODEL_SIGNATURE;
create column table GET_KEY_INFLUENCERS_FROM_MODEL_SIGNATURE like PROCEDURE_SIGNATURE_T;
            
insert into GET_KEY_INFLUENCERS_FROM_MODEL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into GET_KEY_INFLUENCERS_FROM_MODEL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into GET_KEY_INFLUENCERS_FROM_MODEL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into GET_KEY_INFLUENCERS_FROM_MODEL_SIGNATURE values (4, 'USER_APL','SUMMARY_T', 'OUT');
insert into GET_KEY_INFLUENCERS_FROM_MODEL_SIGNATURE values (5, 'USER_APL','INDICATORS_T', 'OUT');
insert into GET_KEY_INFLUENCERS_FROM_MODEL_SIGNATURE values (6, 'USER_APL','INFLUENCERS_T', 'OUT');
insert into GET_KEY_INFLUENCERS_FROM_MODEL_SIGNATURE values (7, 'USER_APL','CONTINUOUS_GROUPS_T', 'OUT');
insert into GET_KEY_INFLUENCERS_FROM_MODEL_SIGNATURE values (8, 'USER_APL','OTHER_GROUPS_T', 'OUT');
call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_GET_KEY_INFLUENCERS_FROM_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','GET_KEY_INFLUENCERS_FROM_MODEL','USER_APL', 'APLWRAPPER_GET_KEY_INFLUENCERS_FROM_MODEL', GET_KEY_INFLUENCERS_FROM_MODEL_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');

drop table OPERATION_CONFIG;
create table OPERATION_CONFIG like OPERATION_CONFIG_T;

drop table INFLUENCERS;
create table INFLUENCERS like INFLUENCERS_T;

drop table CONTINUOUS_GROUPS;
create table CONTINUOUS_GROUPS like CONTINUOUS_GROUPS_T;

drop table OTHER_GROUPS;
create table OTHER_GROUPS like OTHER_GROUPS_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;         
    model_in = select * from MODEL_TRAIN_BIN;             
    config   = select * from OPERATION_CONFIG;            

    APLWRAPPER_GET_KEY_INFLUENCERS_FROM_MODEL(:header, :model_in, :config, out_sum,out_indic,out_influencer, out_continous_groups, out_other_groups);
    
    -- store result into table
    insert into  "USER_APL"."SUMMARY"           select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"        select * from :out_indic;
    insert into  "USER_APL"."INFLUENCERS"       select * from :out_influencer;
    insert into  "USER_APL"."CONTINUOUS_GROUPS" select * from :out_continous_groups;
    insert into  "USER_APL"."OTHER_GROUPS"      select * from :out_other_groups;

	-- show result
    select * from "USER_APL"."SUMMARY";
    select * from "USER_APL"."INDICATORS";
    select * from "USER_APL"."INFLUENCERS";
    select * from "USER_APL"."CONTINUOUS_GROUPS";
    select * from "USER_APL"."OTHER_GROUPS";
END;
