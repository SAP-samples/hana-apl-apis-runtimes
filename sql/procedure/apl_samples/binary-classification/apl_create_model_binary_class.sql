-- ================================================================
-- This scripts demonstrates how to create and train a Gradient
-- Boosting model for a binary classification task

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('ModelFormat', 'bin');


drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- let this table empty to use guess variables

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
insert into VARIABLE_ROLES values ('class', 'target', null, null, null);
-- variable roles are optional, hence the empty table

drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------

drop table CREATE_AND_TRAIN_CONFIG;
create table CREATE_AND_TRAIN_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into CREATE_AND_TRAIN_CONFIG values ('APL/ModelType', 'binary classification',null);

insert into CREATE_AND_TRAIN_CONFIG values ('APL/MaxIterations', '100',null); -- default value: 1000
insert into CREATE_AND_TRAIN_CONFIG values ('APL/EarlyStoppingPatience', '10',null); -- default value: 10
insert into CREATE_AND_TRAIN_CONFIG values ('APL/LearningRate', '.08',null); -- default value: 0.1
insert into CREATE_AND_TRAIN_CONFIG values ('APL/CorrelationsMaxKept', '10',null); -- default value: 1024
insert into CREATE_AND_TRAIN_CONFIG values ('APL/CorrelationsLowerBound', '.99',null); -- default value: 0.50
-- default value: LogLoss. It's possible to specify multiple metrics to get the learning curves
-- last metric in the list is by convention used as the early stopping criterion
insert into CREATE_AND_TRAIN_CONFIG values ('APL/EvalMetric', 'LogLoss,AUC',null);

-- auto selection parameters
insert into CREATE_AND_TRAIN_CONFIG values ('APL/VariableAutoSelection', 'true',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/VariableSelectionPercentageOfContributionKeptByStep', '0.97',null); -- default value: 0.95
insert into CREATE_AND_TRAIN_CONFIG values ('APL/VariableSelectionQualityBar', '0.02',null); -- default value: 0.01
insert into CREATE_AND_TRAIN_CONFIG values ('APL/VariableSelectionMaxIterations', '4',null); -- default value: 2

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from CREATE_AND_TRAIN_CONFIG;            
    var_desc = select * from VARIABLE_DESC;              
    var_role = select * from VARIABLE_ROLES;  

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role,  'APL_SAMPLES','ADULT01',out_model,out_log,out_sum,out_indic);
    
    -- store result into table
    insert into  "USER_APL"."MODEL_TRAIN_BIN" select * from :out_model;
    insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;
    insert into  "USER_APL"."SUMMARY"         select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"      select * from :out_indic;

    -- global perf indicators based on score variable
    select * from "USER_APL"."INDICATORS" where "VARIABLE"='gb_score_class';

    -- global perf indicators based on decision variable
    select * from "USER_APL"."INDICATORS" where "VARIABLE"='gb_decision_class';

    -- global perf indicators based on probability variable
    select * from "USER_APL"."INDICATORS" where "VARIABLE"='gb_proba_class';

    -- variable contributions
    select * from "USER_APL"."INDICATORS" where KEY='VariableContribution';

    -- learning curves on AUC metric used to evaluate the early stopping (indicator key is EvalMetricValue with no suffix)
    select * from "USER_APL"."INDICATORS" where KEY='EvalMetricValue';

    -- learning curves on secondary LogLoss metric (indicator key is suffixed with the metric name)
    select * from "USER_APL"."INDICATORS" where KEY='EvalMetricValue(LogLoss)';

    -- variable correlations
    select * from "USER_APL"."INDICATORS" where KEY='CorrelatedVariable';

    -- summary
    select * from "USER_APL"."SUMMARY";

END;
