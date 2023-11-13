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
drop table GET_MODEL_DEBRIEF_SIGNATURE;
create column table GET_MODEL_DEBRIEF_SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into GET_MODEL_DEBRIEF_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into GET_MODEL_DEBRIEF_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into GET_MODEL_DEBRIEF_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into GET_MODEL_DEBRIEF_SIGNATURE values (4, 'USER_APL','DEBRIEF_METRIC_OID_T', 'OUT');
insert into GET_MODEL_DEBRIEF_SIGNATURE values (5, 'USER_APL','DEBRIEF_PROPERTY_OID_T', 'OUT');
insert into GET_MODEL_DEBRIEF_SIGNATURE values (6, 'USER_APL','SUMMARY_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_GET_MODEL_DEBRIEF');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','GET_MODEL_DEBRIEF','USER_APL', 'APLWRAPPER_GET_MODEL_DEBRIEF', GET_MODEL_DEBRIEF_SIGNATURE);

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
insert into OPERATION_CONFIG values ('APL/DebriefId', '10');
--insert into OPERATION_CONFIG values ('AAPL/DebriefVesrion', '1.2.0.0');

drop table DEBRIEF_METRIC;
create table DEBRIEF_METRIC like DEBRIEF_METRIC_OID_T;

drop table DEBRIEF_PROPERTY;
create table DEBRIEF_PROPERTY like DEBRIEF_PROPERTY_OID_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
-- extra info from metric and property
-- --------------------------------------------------------------------------
drop view DEBRIEF_MODEL;
create view  DEBRIEF_MODEL  as (
SELECT "OID", "OWNER_ID" as "ID",
  MAX(CASE WHEN NAME='NAME' THEN "VALUE" ELSE NULL END) AS "NAME",
  MAX(CASE WHEN NAME='VERSION' THEN "VALUE" ELSE NULL END) AS "VERSION",
  MAX(CASE WHEN NAME='AUTHOR' THEN "VALUE" ELSE NULL END) AS "AUTHOR",
  MAX(CASE WHEN NAME='BUILD_DATE' THEN "VALUE" ELSE NULL END) AS "BUILD_DATE",
  MAX(CASE WHEN NAME='CUTTING' THEN "VALUE" ELSE NULL END) AS "CUTTING"
FROM "USER_APL"."DEBRIEF_PROPERTY"  WHERE "OWNER_TYPE" = 'MODEL'  and  "NAME" in  ('NAME','VERSION', 'AUTHOR','BUILD_DATE','CUTTING' ) GROUP BY "OWNER_ID", "OID" );


drop view DEBRIEF_DATASET;
create view  DEBRIEF_DATASET  as (
SELECT "OID", "OWNER_ID" as "ID",
  MAX(CASE WHEN NAME='NAME' THEN "VALUE" ELSE NULL END) AS "NAME",
  MAX(CASE WHEN NAME='STORE_NAME' THEN "VALUE" ELSE NULL END) AS "STORE_NAME",
  MAX(CASE WHEN NAME='STORE_SPACE' THEN TO_NVARCHAR("LONG_VALUE") ELSE NULL END) AS "STORE_SPACE",
  MAX(CASE WHEN NAME='FILTER_CONDITION' THEN TO_NVARCHAR("LONG_VALUE") ELSE NULL END) AS "FILTER_CONDITION",
  MAX(CASE WHEN NAME='NB_RECORDS' THEN "D_VALUE" ELSE NULL END) AS "NB_RECORDS",
  MAX(CASE WHEN NAME='TOTAL_WEIGHT' THEN "D_VALUE" ELSE NULL END) AS "TOTAL_WEIGHT"
FROM "USER_APL"."DEBRIEF_PROPERTY"  WHERE "OWNER_TYPE" = 'DATASET'  and  "NAME" in  ('NAME','STORE_NAME', 'STORE_SPACE','FILTER_CONDITION','NB_RECORDS', 'TOTAL_WEIGHT' ) GROUP BY "OWNER_ID", "OID" );

drop view DEBRIEF_VARIABLE;
create view  DEBRIEF_VARIABLE  as (
SELECT "OID",  "OWNER_ID" as "ID",
  MAX(CASE WHEN NAME='NAME' THEN "VALUE" ELSE NULL END) AS "NAME",
  MAX(CASE WHEN NAME='VALUE_TYPE' THEN "VALUE" ELSE NULL END) AS "VALUE_TYPE",
  MAX(CASE WHEN NAME='SOTRAGE_TYPE' THEN "VALUE" ELSE NULL END) AS "SOTRAGE_TYPE",
  MAX(CASE WHEN NAME='ROLE' THEN "VALUE" ELSE NULL END) AS "ROLE",
  MAX(CASE WHEN NAME='KEY_LEVEL' THEN "VALUE" ELSE NULL END) AS "KEY_LEVEL",
  MAX(CASE WHEN NAME='ORDER_LEVEL' THEN "VALUE" ELSE NULL END) AS "ORDER_LEVEL",
  MAX(CASE WHEN NAME='MISSING_STRING' THEN "VALUE" ELSE NULL END) AS "MISSING_STRING",  
  MAX(CASE WHEN NAME='DESCRIPTION' THEN "VALUE" ELSE NULL END) AS "DESCRIPTION",
  MAX(CASE WHEN NAME='TARGET_KEY' THEN "VALUE" ELSE NULL END) AS "TARGET_KEY",
  MAX(CASE WHEN NAME='ESTIMATOR_OF' THEN "I_VALUE" ELSE NULL END) AS "ESTIMATOR_OF"
FROM "USER_APL"."DEBRIEF_PROPERTY"  WHERE "OWNER_TYPE" = 'VARIABLE'  and  "NAME" in  ('NAME','VALUE_TYPE', 'SOTRAGE_TYPE','ROLE','KEY_LEVEL','ORDER_LEVEL','MISSING_STRING','DESCRIPTION','TARGET_KEY','ESTIMATOR_OF' ) GROUP BY "OWNER_ID", "OID" );

drop view DEBRIEF_VARIABLE_PERFORMANCE;
create view  DEBRIEF_VARIABLE_PERFORMANCE  as (
SELECT "OID",  "OWNER_ID" as "ID",
  MAX(CASE WHEN NAME='VARIABLE_ID' THEN "I_VALUE" ELSE NULL END) AS "VARIABLE_ID",
  MAX(CASE WHEN NAME='TARGET_ID' THEN "I_VALUE" ELSE NULL END) AS "TARGET_ID"
FROM  "USER_APL"."DEBRIEF_PROPERTY"  WHERE "OWNER_TYPE" = 'VARIABLE_PERFORMANCE'  and  "NAME" in  ('VARIABLE_ID','TARGET_ID') GROUP BY "OWNER_ID", "OID" );

drop view DEBRIEF_VARIABLE_PERFORMANCE_STAT;
create view  DEBRIEF_VARIABLE_PERFORMANCE_STAT  as (
SELECT "OID",  "OWNER_ID" as "ID", "DATASET_ID",
  MAX(CASE WHEN NAME='KI' THEN "VALUE" ELSE NULL END) AS "KI",
  MAX(CASE WHEN NAME='KR' THEN "VALUE" ELSE NULL END) AS "KR",
  MAX(CASE WHEN NAME='AUC' THEN "VALUE" ELSE NULL END) AS "AUC"
FROM  "USER_APL"."DEBRIEF_METRIC"  WHERE "OWNER_TYPE" = 'VARIABLE_PERFORMANCE_STAT'  and  "NAME" in  ('KI','KR','AUC') GROUP BY "OWNER_ID", "OID", "DATASET_ID" );

DO BEGIN     
    header   = select * from FUNC_HEADER;       
    modle_in = select * from MODEL_TRAIN_BIN;             
    config    = select * from OPERATION_CONFIG;          

    APLWRAPPER_GET_MODEL_DEBRIEF(:header, :modle_in, :config, out_debrief_metric,out_debrief_property, out_summ);
    
    -- store result into table
    insert into  "USER_APL"."DEBRIEF_METRIC"   select * from :out_debrief_metric;
    insert into  "USER_APL"."DEBRIEF_PROPERTY" select * from :out_debrief_property;
    insert into  "USER_APL"."SUMMARY"          select * from :out_summ;

    select * from DEBRIEF_MODEL; 
    select * from DEBRIEF_DATASET;
    select * from DEBRIEF_VARIABLE;
    select * from DEBRIEF_VARIABLE_PERFORMANCE;
    select * from DEBRIEF_VARIABLE_PERFORMANCE_STAT;

END;
