-- ================================================================
-- APL_AREA, DEBRIEF_APPLY_RESULT using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see APL_admin.sql).
-- Assumption 2: The APL table types have been created (see APL_create_table_types.sql).
-- Assumption 3: There's a valid apply form a model (created by APL) IN the ADULT01_APPLY table.
--  @depend(apl_apply_model.sql)

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
connect USER_APL password Password1;

drop type ADULT01_T_OUT;
create type ADULT01_T_OUT as table (
    "KxIndex" INTEGER,
    "class" INTEGER,
    "rr_class" DOUBLE
);

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------

-- the AFL wrapper generator needs the signature of the expected stored proc
drop table DEBRIEF_APPLY_RESULT_SIGNATURE;
create column table DEBRIEF_APPLY_RESULT_SIGNATURE  like PROCEDURE_SIGNATURE_T;
insert into DEBRIEF_APPLY_RESULT_SIGNATURE values (1, 'USER_APL', 'FUNCTION_HEADER_T', 'IN');
insert into DEBRIEF_APPLY_RESULT_SIGNATURE values (2, 'USER_APL', 'OPERATION_CONFIG_T', 'IN');
insert into DEBRIEF_APPLY_RESULT_SIGNATURE values (3, 'USER_APL', 'VARIABLE_DESC_T', 'IN');
insert into DEBRIEF_APPLY_RESULT_SIGNATURE values (4, 'USER_APL', 'VARIABLE_ROLES_T', 'IN');
insert into DEBRIEF_APPLY_RESULT_SIGNATURE values (5, 'USER_APL', 'ADULT01_T_OUT', 'IN');
insert into DEBRIEF_APPLY_RESULT_SIGNATURE values (6, 'USER_APL', 'ADULT01_T_OUT', 'IN');
insert into DEBRIEF_APPLY_RESULT_SIGNATURE values (7, 'USER_APL', 'ADULT01_T_OUT', 'IN');
insert into DEBRIEF_APPLY_RESULT_SIGNATURE values (8, 'USER_APL', 'OPERATION_LOG_T', 'OUT');
insert into DEBRIEF_APPLY_RESULT_SIGNATURE values (9, 'USER_APL', 'SUMMARY_T', 'OUT');
insert into DEBRIEF_APPLY_RESULT_SIGNATURE values (10, 'USER_APL', 'INDICATORS_DATASET_T', 'OUT');
insert into DEBRIEF_APPLY_RESULT_SIGNATURE values (11, 'USER_APL', 'PROFITCURVE_T', 'OUT');


call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_DEBRIEF_APPLY_RESULT');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA', 'DEBRIEF_APPLY_RESULT', 'USER_APL', 'APLWRAPPER_DEBRIEF_APPLY_RESULT', DEBRIEF_APPLY_RESULT_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create COLUMN table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', 'foobar');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table STAT_CONFIG;
create table STAT_CONFIG like OPERATION_CONFIG_T;
insert into STAT_CONFIG values ('APL/VariableEstimatorOf', 'rr_class;class');
insert into STAT_CONFIG values ('APL/CurveType','detected');


drop table STAT_VARIABLE_DESC;
create table STAT_VARIABLE_DESC like VARIABLE_DESC_T;
insert into STAT_VARIABLE_DESC values(0,'KxIndex','integer','continuous',1,0,'','','');
insert into STAT_VARIABLE_DESC values(1,'class','integer','nominal',0,0,'','','');
insert into STAT_VARIABLE_DESC values(2,'rr_class','number','continuous',0,0,'','','');

drop table STAT_VARIABLE_ROLES;
create table STAT_VARIABLE_ROLES like VARIABLE_ROLES_T;
insert into STAT_VARIABLE_ROLES values ('class', 'target');

drop table OPERATION_LOG;
create COLUMN table OPERATION_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create COLUMN table SUMMARY like SUMMARY_T;

drop table INDICATORS_DATASET;
create COLUMN table INDICATORS_DATASET like INDICATORS_DATASET_T;

drop table PROFITCURVE;
create COLUMN table PROFITCURVE like PROFITCURVE_T;

drop view ESTIMATION;
create view ESTIMATION as (select * from USER_APL.ADULT01_APPLY where "KxIndex" <= 39000 order by "KxIndex");

drop view VALIDATION;
create view VALIDATION as (select * from USER_APL.ADULT01_APPLY where "KxIndex" > 39000 and "KxIndex" <= 44000 order by "KxIndex");

drop view TEST_VIEW;
create view TEST_VIEW as (select * from USER_APL.ADULT01_APPLY where "KxIndex" > 44000 order by "KxIndex");

DO BEGIN     
    header      = select * from FUNC_HEADER;
    config      = select * from STAT_CONFIG; 
    var_desc    = select * from STAT_VARIABLE_DESC;              
    var_role    = select * from STAT_VARIABLE_ROLES;  
    estimation  = select * from ESTIMATION;  
	validation  = select * from VALIDATION;  
	test        = select * from TEST_VIEW;  
           

	APLWRAPPER_DEBRIEF_APPLY_RESULT(:header, :config, :var_desc, :var_role, :estimation,:validation,:test,out_log, out_summ, out_indic, out_curve);
    
    -- store result into table
    insert into  "USER_APL"."OPERATION_LOG"       select * from :out_log;
    insert into  "USER_APL"."SUMMARY"             select * from :out_summ;
    insert into  "USER_APL"."INDICATORS_DATASET"  select * from :out_indic;
    insert into  "USER_APL"."PROFITCURVE"         select * from :out_curve;

	-- show result
    select * from INDICATORS_DATASET;
    select * from PROFITCURVE; 
END;
