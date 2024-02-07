-- ================================================================
-- APL_AREA, APPLY_MODEL, using a binary format for the model
-- This script demonstrates the application of the binary classification model
-- to predict the target and to get the individual contributions per input
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(apl_createmodel_and_train_ex.sql)
--  @depend(apl_apply_proc.sql)

connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);
insert into APPLY_CONFIG values ('APL/ApplyPredictedValue', 'false',null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations', 'true', null);

call "apl_apply_example"(FUNC_HEADER, MODEL_TRAIN_BIN, APPLY_CONFIG,  'APL_SAMPLES','ADULT01', 'USER_APL','ADVANCED_SETTINGS_APPLY');
select * from "USER_APL"."ADVANCED_SETTINGS_APPLY";

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/AbsoluteExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveExplanationsCount', '0', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeExplanationsCount', '0', null);

call "apl_apply_example"(FUNC_HEADER, MODEL_TRAIN_BIN, APPLY_CONFIG,  'APL_SAMPLES','ADULT01', 'USER_APL','ADVANCED_SETTINGS_APPLY');
select * from "USER_APL"."ADVANCED_SETTINGS_APPLY";

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/AbsoluteExplanationsCount', '0', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeExplanationsCount', '5', null);

call "apl_apply_example"(FUNC_HEADER, MODEL_TRAIN_BIN, APPLY_CONFIG,  'APL_SAMPLES','ADULT01', 'USER_APL','ADVANCED_SETTINGS_APPLY');
select * from "USER_APL"."ADVANCED_SETTINGS_APPLY";

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/AbsoluteExplanationsCount', '0', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveOthers', 'true', null);

call "apl_apply_example"(FUNC_HEADER, MODEL_TRAIN_BIN, APPLY_CONFIG,  'APL_SAMPLES','ADULT01', 'USER_APL','ADVANCED_SETTINGS_APPLY');
select * from "USER_APL"."ADVANCED_SETTINGS_APPLY";

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/AbsoluteExplanationsCount', '0', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveOthers', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeOthers', 'true', null);

call "apl_apply_example"(FUNC_HEADER, MODEL_TRAIN_BIN, APPLY_CONFIG,  'APL_SAMPLES','ADULT01', 'USER_APL','ADVANCED_SETTINGS_APPLY');
select * from "USER_APL"."ADVANCED_SETTINGS_APPLY";

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/AbsoluteExplanationsCount', '0', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveOthers', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeOthers', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/ExplanationName', 'true', null);

call "apl_apply_example"(FUNC_HEADER, MODEL_TRAIN_BIN, APPLY_CONFIG,  'APL_SAMPLES','ADULT01', 'USER_APL','ADVANCED_SETTINGS_APPLY');
select * from "USER_APL"."ADVANCED_SETTINGS_APPLY";

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/AbsoluteExplanationsCount', '0', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveOthers', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeOthers', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/ExplanationName', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/ExplanationValue', 'true', null);

call "apl_apply_example"(FUNC_HEADER, MODEL_TRAIN_BIN, APPLY_CONFIG,  'APL_SAMPLES','ADULT01', 'USER_APL','ADVANCED_SETTINGS_APPLY');
select * from "USER_APL"."ADVANCED_SETTINGS_APPLY";

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/AbsoluteExplanationsCount', '0', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveOthers', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeOthers', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/ExplanationName', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/ExplanationValue', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/ExplanationStrength', 'true', null);

call "apl_apply_example"(FUNC_HEADER, MODEL_TRAIN_BIN, APPLY_CONFIG,  'APL_SAMPLES','ADULT01', 'USER_APL','ADVANCED_SETTINGS_APPLY');
select * from "USER_APL"."ADVANCED_SETTINGS_APPLY";

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/AbsoluteExplanationsCount', '0', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveOthers', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeOthers', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/ExplanationName', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/ExplanationValue', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/ExplanationStrength', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/ExplanationContribution', 'true', null);


call "apl_apply_example"(FUNC_HEADER, MODEL_TRAIN_BIN, APPLY_CONFIG,  'APL_SAMPLES','ADULT01', 'USER_APL','ADVANCED_SETTINGS_APPLY');
select * from "USER_APL"."ADVANCED_SETTINGS_APPLY";
