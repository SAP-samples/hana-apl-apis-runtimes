/* 
  CREATE_MODEL_AND_TRAIN
*/
connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';
/* 
  CREATING AND TRAINING THE APL CLASSIFICATION MODEL  
*/

-- Create the tables specifying the model and describing the business data 
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', 'Claims');

drop table CREATE_AND_TRAIN_CONFIG;
create table CREATE_AND_TRAIN_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into CREATE_AND_TRAIN_CONFIG values ('APL/ModelType', 'regression/classification',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/CuttingStrategy', 'random with no test',null);

drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
insert into VARIABLE_DESC values (0,'CLAIM_ID','string','nominal',1,0,NULL,NULL,'Unique Identifier of a claim',NULL);
insert into VARIABLE_DESC values (1,'DAYS_TO_REPORT','integer','continuous',0,0,NULL,NULL,NULL,NULL);
insert into VARIABLE_DESC values (2,'BODILY_INJURY_AMOUNT','integer','continuous',0,0,NULL,NULL,NULL,NULL);
insert into VARIABLE_DESC values (3,'PROPERTY_DAMAGE','integer','continuous',0,0,NULL,NULL,NULL,NULL);
insert into VARIABLE_DESC values (4,'PREVIOUS_CLAIMS','integer','ordinal',0,0,NULL,NULL,'Number of previous claims',NULL);
insert into VARIABLE_DESC values (5,'PAYMENT_METHOD','string','nominal',0,0,NULL,NULL,NULL,NULL);
insert into VARIABLE_DESC values (6,'IS_REAR_END_COLLISION','string','nominal',0,0,NULL,NULL,NULL,NULL);
insert into VARIABLE_DESC values (7,'PREM_AMOUNT','string','nominal',0,0,NULL,NULL,NULL,NULL);
insert into VARIABLE_DESC values (8,'AGE','integer','continuous',0,0,NULL,NULL,NULL,NULL);
insert into VARIABLE_DESC values (9,'GENDER','string','nominal',0,0,NULL,NULL,NULL,NULL);
insert into VARIABLE_DESC values (10,'MARITAL_STATUS','string','nominal',0,0,NULL,NULL,NULL,NULL);
insert into VARIABLE_DESC values (11,'INCOME_ESTIMATE','number','continuous',0,0,NULL,NULL,NULL,NULL);
insert into VARIABLE_DESC values (12,'INCOME_CATEGORY','integer','ordinal',0,0,NULL,NULL,NULL,NULL);
insert into VARIABLE_DESC values (13,'POLICY_HOLDER','string','nominal',0,0,NULL,NULL,NULL,NULL);
insert into VARIABLE_DESC values (14,'IS_FRAUD','string','nominal',0,0,NULL,NULL,'Yes/No flag',NULL);

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
-- by not indicating a target column here, the engine will use the last column as the target variable

-- Create the output tables
drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from CREATE_AND_TRAIN_CONFIG;            
    var_desc = select * from VARIABLE_DESC;              
    var_role = select * from VARIABLE_ROLES;  

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(
      :header, :config, :var_desc,:var_role, -- APL Inputs
      'APL_SAMPLES','AUTO_CLAIMS_FRAUD'      -- Business data    
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
    INDICATORS 
    where 
    OID = 'Claims' and VARIABLE = 'IS_FRAUD' and KEY in ('PredictivePower','PredictionConfidence');

    -- Display Variable Contributions  
    select 
    OID as "Model Name",
    row_number() OVER (partition by OID order by TO_NVARCHAR(VALUE) desc) as "Rank",
    VARIABLE as "Explanatory Variable", 
    round(to_double(TO_NVARCHAR(VALUE)) *100 , 2) as "Individual Contribution",
    round(sum(to_double(TO_NVARCHAR(VALUE))) OVER (partition by OID order by TO_NVARCHAR(VALUE) desc) *100 ,2) 
    as "Cumulative Contribution"
    from 
    INDICATORS 
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
    SUMMARY 
    where 
    OID = 'Claims' and (KEY IN ('ModelLearningTime','NbVariablesKept') or KEY like 'Model%Count')
    order by 1;

END;
