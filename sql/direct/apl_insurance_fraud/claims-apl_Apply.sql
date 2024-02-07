/* 
  GENERATING THE APL PROCEDURE : APPLY_MODEL
  (we assume that the training on past claims data is done)
  @depend(claims-apl_Create_Train.sql)
*/
connect USER_APL password Password1;
set schema USER_APL;

-- Create the table in which we will put the prediction scores
drop type CLAIMS_SCORES_T_OUT;
create type CLAIMS_SCORES_T_OUT as table (
    "CLAIM_ID" varchar(10),
    "IS_FRAUD" varchar(10),
    "rr_IS_FRAUD" double,
    "decision_rr_IS_FRAUD" varchar(3),
    "proba_decision_rr_IS_FRAUD" Double
);
-- Create the signature of the procedure
drop table APPLY_MODEL_SIGNATURE;
create table APPLY_MODEL_SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into APPLY_MODEL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',   'IN');
insert into APPLY_MODEL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T',     'IN');
insert into APPLY_MODEL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T',  'IN');
insert into APPLY_MODEL_SIGNATURE values (4, 'USER_APL','AUTO_CLAIMS_NEW_T',   'IN');
insert into APPLY_MODEL_SIGNATURE values (5, 'USER_APL','CLAIMS_SCORES_T_OUT', 'OUT');
insert into APPLY_MODEL_SIGNATURE values (6, 'USER_APL','OPERATION_LOG_T',     'OUT');

-- Generate the procedure
call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL', 'APLWRAPPER_APPLY_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA', 'APPLY_MODEL', 'USER_APL', 'APLWRAPPER_APPLY_MODEL', APPLY_MODEL_SIGNATURE);

/* 
  APPLYING THE APL CLASSIFICATION MODEL  
*/
-- Create the input tables 

/* we will reuse the table FUNC_HEADER defined previously for the function CREATE_MODEL_AND_TRAIN */

drop table APPLY_CONFIG;
create table APPLY_CONFIG like OPERATION_CONFIG_T;
insert into APPLY_CONFIG values ('APL/ApplyExtraMode','Decision');

-- Create the output tables
drop table CLAIMS_SCORES;
create table CLAIMS_SCORES like CLAIMS_SCORES_T_OUT;

-- Run the APL function and display the individual scores
DO BEGIN     
  header       = select * from FUNC_HEADER;             
  model_in     = select * from MODEL_TRAIN_BIN;             
  apply_config = select * from APPLY_CONFIG; 
  dataset      = select * from APL_SAMPLES.AUTO_CLAIMS_NEW;  
  apply_config = select * from APPLY_CONFIG; 	           
  
  -- Run the APL function and display the individual scores
  APLWRAPPER_APPLY_MODEL(
      :header, :model_in, :apply_config,  -- APL Inputs
      :dataset,                           -- Business data
      clains_scores, out_log );                 -- APL Outputs

  -- store result into table
  insert into  "USER_APL"."CLAIMS_SCORES"       select * from :clains_scores;

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
    :clains_scores
  order by 2 asc, 3 desc, 4 desc;

  select 
  N.*, 
  round("proba_decision_rr_IS_FRAUD" *100,2) as "Fraud Likelihood",
  round("rr_IS_FRAUD" * 100 ,2) as "Fraud Score"
  from 
    :clains_scores S, APL_SAMPLES.AUTO_CLAIMS_NEW N
  where
    S.CLAIM_ID = N.CLAIM_ID and S."decision_rr_IS_FRAUD" = 'Yes'
  order by S."proba_decision_rr_IS_FRAUD" desc, S."rr_IS_FRAUD" desc;

END;
