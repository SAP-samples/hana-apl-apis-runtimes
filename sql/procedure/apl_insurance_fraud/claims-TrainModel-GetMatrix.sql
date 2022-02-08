connect USER_APL password Password1;
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', 'Claims');

drop table CREATE_AND_TRAIN_CONFIG;
create table CREATE_AND_TRAIN_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_DETAILED";
insert into CREATE_AND_TRAIN_CONFIG values ('APL/ModelType', 'regression/classification',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/CuttingStrategy', 'random with no test',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/IndicatorDataset', 'Validation',null);

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

-- Create the output tables
drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS_VALIDATION;
create table INDICATORS_VALIDATION like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table OPERATION_CONFIG;
create table OPERATION_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";

drop table CNF_MTX_INDICATORS;
create table CNF_MTX_INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

DO BEGIN     
    header          = select * from FUNC_HEADER;             
    config          = select * from CREATE_AND_TRAIN_CONFIG; 
    var_desc        = select * from VARIABLE_DESC;              
    var_role        = select * from VARIABLE_ROLES;  
    config_matrix   = select * from OPERATION_CONFIG; 

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(
      :header, :config, :var_desc,:var_role, -- APL Inputs
      'APL_SAMPLES','AUTO_CLAIMS_FRAUD'      -- Business data    
      ,out_model,out_log,out_sum,out_indic); -- APL Outputs

    "SAP_PA_APL"."sap.pa.apl.base::COMPUTE_CONFUSION_MATRIX" (
      :header,:config_matrix, :out_indic,     -- INPUTS
      out_matrix_indic);                      -- OUTPUT

    -- store result into table
    insert into  "USER_APL"."MODEL_TRAIN_BIN"        select * from :out_model;
    insert into  "USER_APL"."OPERATION_LOG"          select * from :out_log;
    insert into  "USER_APL"."SUMMARY"                select * from :out_sum;
    insert into  "USER_APL"."INDICATORS_VALIDATION"  select * from :out_indic;
    insert into  "USER_APL"."CNF_MTX_INDICATORS"     select * from :out_matrix_indic;


    select * from CNF_MTX_INDICATORS;
    -- Confusion Matrix : Count and Percent values
    With MT as
    ( select key as indicator_name, round(to_double(value),2) as indicator_value from CNF_MTX_INDICATORS )  
    select 
    'Actual Yes' as "Actual/Predicted", 
    sum(case when indicator_name = 'True_Positive' then indicator_value else null end) as "Predicted Yes",
    sum(case when indicator_name = 'False_Negative' then indicator_value else null end) as "Predicted No",
    sum(case when indicator_name = 'Actual_Positive' then indicator_value else null end) as "Total",
    ' '  as " ",
    sum(case when indicator_name = 'Percent_True_Positive' then indicator_value else null end) as "% Predicted Yes",
    sum(case when indicator_name = 'Percent_False_Negative' then indicator_value else null end) as "% Predicted No",
    sum(case when indicator_name = 'Percent_Actual_Positive' then indicator_value else null end) as "% Total"
    from MT
    UNION
    select
    'Actual No' , 
    sum(case when indicator_name = 'False_Positive' then indicator_value else null end) ,
    sum(case when indicator_name = 'True_Negative' then indicator_value else null end) ,
    sum(case when indicator_name = 'Actual_Negative' then indicator_value else null end) ,
    ' ' ,
    sum(case when indicator_name = 'Percent_False_Positive' then indicator_value else null end),
    sum(case when indicator_name = 'Percent_True_Negative' then indicator_value else null end) ,
    sum(case when indicator_name = 'Percent_Actual_Negative' then indicator_value else null end) 
    from MT
    UNION
    select
    'Total' , 
    sum(case when indicator_name = 'Predicted_Positive' then indicator_value else null end) ,
    sum(case when indicator_name = 'Predicted_Negative' then indicator_value else null end) ,
    sum(case when indicator_name in ('Actual_Positive','Actual_Negative')  then indicator_value else null end),
    ' ',
    sum(case when indicator_name = 'Percent_Predicted_Positive' then indicator_value else null end),
    sum(case when indicator_name = 'Percent_Predicted_Negative' then indicator_value else null end) ,
    sum(case when indicator_name in ('Percent_Actual_Positive','Percent_Actual_Negative') then indicator_value else null end)
    from MT
    ;

    -- Performance Indicators
    select 
    key as "Indicator Name", 
    round(to_double(value),4) as "Indicator Value"  
    from 
    CNF_MTX_INDICATORS 
    where 
    key not like '%tive' and key != 'Threshold'
    order by 
    1
    ;

END
