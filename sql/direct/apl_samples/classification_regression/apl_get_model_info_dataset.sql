-- ================================================================
-- APL_AREA, GET_VARIABLE_INDICATORS, using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(apl_createmodel_and_train.sql)

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
connect USER_APL password Password1;
-- the AFL wrapper generator needs the signature of the expected stored proc
drop table GET_MODEL_INFO_SIGNATURE;
create column table GET_MODEL_INFO_SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into GET_MODEL_INFO_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into GET_MODEL_INFO_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into GET_MODEL_INFO_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into GET_MODEL_INFO_SIGNATURE values (4, 'USER_APL','SUMMARY_T', 'OUT');
insert into GET_MODEL_INFO_SIGNATURE values (5, 'USER_APL','VARIABLE_ROLES_WITH_COMPOSITES_OID_T', 'OUT');
insert into GET_MODEL_INFO_SIGNATURE values (6, 'USER_APL','VARIABLE_DESC_OID_T', 'OUT');
insert into GET_MODEL_INFO_SIGNATURE values (7, 'USER_APL','INDICATORS_DATASET_T', 'OUT');
insert into GET_MODEL_INFO_SIGNATURE values (8, 'USER_APL','PROFITCURVE_T', 'OUT');
insert into GET_MODEL_INFO_SIGNATURE values (9, 'USER_APL','TABLE_TYPE_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_GET_MODEL_INFO');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','GET_MODEL_INFO','USER_APL', 'APLWRAPPER_GET_MODEL_INFO', GET_MODEL_INFO_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

drop table OPERATION_CONFIG;
create table OPERATION_CONFIG like OPERATION_CONFIG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_OID_T;

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_WITH_COMPOSITES_OID_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_DATASET_T;

drop table PROFITCURVES;
create table PROFITCURVES like PROFITCURVE_T;


drop table SCHEMA_TRAINNING;
create table SCHEMA_TRAINNING like TABLE_TYPE_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    modle_in = select * from MODEL_TRAIN_BIN;             
    config    = select * from OPERATION_CONFIG;          

    APLWRAPPER_GET_MODEL_INFO(:header, :modle_in, :config, out_summary, out_variable_roles, out_variable_desc, out_indicators, out_profitcurves ,out_schema_trainning);
    
    -- store result into table
	insert into  "USER_APL"."SUMMARY" select * from :out_summary;
	insert into  "USER_APL"."VARIABLE_ROLES" select * from :out_variable_roles;
	insert into  "USER_APL"."VARIABLE_DESC" select * from :out_variable_desc;
	insert into  "USER_APL"."INDICATORS" select * from :out_indicators;
	insert into  "USER_APL"."PROFITCURVES" select * from :out_profitcurves;
	insert into  "USER_APL"."SCHEMA_TRAINNING" select * from :out_schema_trainning;

	-- show result
    select * from "USER_APL"."SUMMARY";
    select * from "USER_APL"."VARIABLE_ROLES";
    select * from "USER_APL"."VARIABLE_DESC";
    select * from "USER_APL"."INDICATORS";
    select * from "USER_APL"."PROFITCURVES";
    select * from "USER_APL"."SCHEMA_TRAINNING";    
    select * from "USER_APL"."INDICATORS" where "KEY" in  ('L1','L2','Linf', 'ErrorMean', 'ErrorStdDev', 'R2' ,  'ClassificationRate' );
END;

