/* 
  GENERATING THE APL PROCEDURE : CREATE_MODEL_AND_TRAIN
  (we assume that the APL table types exist already)   
   @depend(claims-tables_types.sql)
*/
connect USER_APL password Password1;
set schema USER_APL;

-- Create the signature of the procedure
drop table CREATE_MODEL_AND_TRAIN_SIGNATURE;
create table CREATE_MODEL_AND_TRAIN_SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',   'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T',  'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_T',     'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_T',    'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (5, 'USER_APL','AUTO_CLAIMS_FRAUD_T', 'IN');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (6, 'USER_APL','MODEL_BIN_OID_T',     'OUT');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (7, 'USER_APL','OPERATION_LOG_T',     'OUT');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (8, 'USER_APL','SUMMARY_T',           'OUT');
insert into CREATE_MODEL_AND_TRAIN_SIGNATURE values (9, 'USER_APL','INDICATORS_T',        'OUT');

-- Generate the procedure
call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_CREATE_MODEL_AND_TRAIN');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','CREATE_MODEL_AND_TRAIN','USER_APL', 'APLWRAPPER_CREATE_MODEL_AND_TRAIN', CREATE_MODEL_AND_TRAIN_SIGNATURE);

/* 
  CREATING AND TRAINING THE APL CLASSIFICATION MODEL  
*/

-- Create the tables specifying the model and describing the business data 
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', 'Claims');

drop table CREATE_AND_TRAIN_CONFIG;
create table CREATE_AND_TRAIN_CONFIG like OPERATION_CONFIG_T;
insert into CREATE_AND_TRAIN_CONFIG values ('APL/ModelType', 'regression/classification');
insert into CREATE_AND_TRAIN_CONFIG values ('APL/CuttingStrategy', 'random with no test');

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
insert into VARIABLE_DESC values (0,'CLAIM_ID','string','nominal',1,0,NULL,NULL,'Unique Identifier of a claim');
insert into VARIABLE_DESC values (1,'DAYS_TO_REPORT','integer','continuous',0,0,NULL,NULL,NULL);
insert into VARIABLE_DESC values (2,'BODILY_INJURY_AMOUNT','integer','continuous',0,0,NULL,NULL,NULL);
insert into VARIABLE_DESC values (3,'PROPERTY_DAMAGE','integer','continuous',0,0,NULL,NULL,NULL);
insert into VARIABLE_DESC values (4,'PREVIOUS_CLAIMS','integer','ordinal',0,0,NULL,NULL,'Number of previous claims');
insert into VARIABLE_DESC values (5,'PAYMENT_METHOD','string','nominal',0,0,NULL,NULL,NULL);
insert into VARIABLE_DESC values (6,'IS_REAR_END_COLLISION','string','nominal',0,0,NULL,NULL,NULL);
insert into VARIABLE_DESC values (7,'PREM_AMOUNT','string','nominal',0,0,NULL,NULL,NULL);
insert into VARIABLE_DESC values (8,'AGE','integer','continuous',0,0,NULL,NULL,NULL);
insert into VARIABLE_DESC values (9,'GENDER','string','nominal',0,0,NULL,NULL,NULL);
insert into VARIABLE_DESC values (10,'MARITAL_STATUS','string','nominal',0,0,NULL,NULL,NULL);
insert into VARIABLE_DESC values (11,'INCOME_ESTIMATE','number','continuous',0,0,NULL,NULL,NULL);
insert into VARIABLE_DESC values (12,'INCOME_CATEGORY','integer','ordinal',0,0,NULL,NULL,NULL);
insert into VARIABLE_DESC values (13,'POLICY_HOLDER','string','nominal',0,0,NULL,NULL,NULL);
insert into VARIABLE_DESC values (14,'IS_FRAUD','string','nominal',0,0,NULL,NULL,'Yes/No flag');

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_T;
-- by not indicating a target column here, the engine will use the last column as the target variable

-- Create the output tables
drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like MODEL_BIN_OID_T;

drop table OPERATION_LOG;
create table OPERATION_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from CREATE_AND_TRAIN_CONFIG;            
    var_desc = select * from VARIABLE_DESC;              
    var_role = select * from VARIABLE_ROLES;  
    dataset  = select * from APL_SAMPLES.AUTO_CLAIMS_FRAUD;  

    APLWRAPPER_CREATE_MODEL_AND_TRAIN(
      :header, :config, :var_desc,:var_role, -- APL Inputs
      :dataset                               -- Business data    
      ,out_model,out_log,out_sum,out_indic); -- APL Outputs

    -- store result into table
    insert into  "USER_APL"."MODEL_TRAIN_BIN" select * from :out_model;
    insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;
    insert into  "USER_APL"."SUMMARY"         select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"      select * from :out_indic;

    -- Display Model Quality 
    select 
    case when key = 'PredictivePower' then 'Model KI' else 'Model KR' end as "Quality Indicators", 
    round(to_double(value) *100 , 2) as "Percent Value"
    from 
     "USER_APL"."INDICATORS"
    where 
    OID = 'Claims' and VARIABLE = 'IS_FRAUD' and KEY in ('PredictivePower','PredictionConfidence');

    -- Display Variable Contributions  
    select 
    OID as "Model Name",
    row_number() OVER (partition by OID order by to_double(VALUE) desc) as "Rank",
    VARIABLE as "Explanatory Variable", 
    round(to_double(VALUE) *100 , 2) as "Individual Contribution",
    round(sum(to_double(VALUE)) OVER (partition by OID order by to_double(VALUE) desc) *100 ,2) 
    as "Cumulative Contribution"
    from 
     "USER_APL"."INDICATORS"
    where 
    OID = 'Claims'  and TARGET = 'IS_FRAUD' and 
    KEY = 'MaximumSmartVariableContribution'
    order by 4 desc;

    -- Display Learning Time
    select 
    case key 
      when 'ModelVariableCount'			then 'Initial Number of Variables' 
      when 'ModelSelectedVariableCount'	then 'Number of Explanatory Variables'
      when 'NbVariablesKept'				then 'Number of Explanatory Variables'
      when 'ModelRecordCount'				then 'Number of Records'
      when 'ModelLearningTime' 			then 'Time to learn in seconds'
      else null 
      end as "Training Summary",
    to_double(value) as "Value"
    from 
      "USER_APL"."INDICATORS"
    where 
    OID = 'Claims' and (KEY IN ('ModelLearningTime','NbVariablesKept') or KEY like 'Model%Count')
    order by 1;

END;

