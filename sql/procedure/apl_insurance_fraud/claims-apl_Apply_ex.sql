/* 
  GENERATING THE APL PROCEDURE : APPLY_MODEL
  (we assume that the training on past claims data is done)
  @depend(claims-apl_Create_Train_ex.sql)
*/
connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- Create the table in which we will put the prediction scores
drop type CLAIMS_SCORES_T_OUT;
create type CLAIMS_SCORES_T_OUT as table (
    "CLAIM_ID" varchar(10),
    "IS_FRAUD" varchar(10),
    "rr_IS_FRAUD" double,
    "decision_rr_IS_FRAUD" varchar(3),
    "proba_decision_rr_IS_FRAUD" Double
);

/* 
  APPLYING THE APL CLASSIFICATION MODEL  
*/
-- Create the input tables 

/* we will reuse the table FUNC_HEADER defined previously for the function CREATE_MODEL_AND_TRAIN */

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode','Decision',null);

-- Create the output tables
drop table CLAIMS_SCORES;
create column table CLAIMS_SCORES like CLAIMS_SCORES_T_OUT;

drop table APPLY_LOG;
create column table APPLY_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

-- Run the APL function and display the individual scores
DO BEGIN     
  header       = select * from FUNC_HEADER;             
  model_in     = select * from MODEL_TRAIN_BIN;             
  apply_config = select * from APPLY_CONFIG; 
  
  -- Run the APL function and display the individual scores
  "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL"(
      :header, :model_in, :apply_config,  -- APL Inputs
      'APL_SAMPLES','AUTO_CLAIMS_NEW',    -- Business data
      'USER_APL','CLAIMS_SCORES', out_log, out_sum );                 -- APL Outputs

  -- store result into table
  insert into  "USER_APL"."APPLY_LOG"  select * from :out_log;
  insert into  "USER_APL"."SUMMARY"    select * from :out_sum;
  
  -- show result
  select 
  CLAIM_ID as "Claim ID", 
  case "decision_rr_IS_FRAUD" 
    when 'Yes' then 'Fraudulent Claim' 
    when 'No'  then 'Legitimate Claim' 
    else Null 
  End as "Prediction", 
  round("proba_decision_rr_IS_FRAUD" *100,2) as "Percent Likelihood",
  round("rr_IS_FRAUD" * 100 ,2) as "Fraud Score"
  from 
  CLAIMS_SCORES
  order by 2 asc, 3 desc, 4 desc;

  select 
  N.*, 
  round("proba_decision_rr_IS_FRAUD" *100,2) as "Fraud Likelihood",
  round("rr_IS_FRAUD" * 100 ,2) as "Fraud Score"
  from 
  CLAIMS_SCORES S, APL_SAMPLES.AUTO_CLAIMS_NEW N
  where
  S.CLAIM_ID = N.CLAIM_ID and S."decision_rr_IS_FRAUD" = 'Yes'
  order by S."proba_decision_rr_IS_FRAUD" desc, S."rr_IS_FRAUD" desc;

END;
