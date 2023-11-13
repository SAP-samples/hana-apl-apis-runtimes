-- ================================================================
-- APL_AREA, APPLY_MODEL, using a binary format for the model
-- This script demonstrates the application of the binary classification model
-- to output the reason codes
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(apl_create_model_binary_class.sql)
--  @depend(apl_apply_proc.sql)

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';
-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table APPLY_LOG;
create column table APPLY_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create column table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";


-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
--  Apply the model to get top 2 and bottom 1 reason codes via the advanced apply settings
-- --------------------------------------------------------------------------
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
insert into APPLY_CONFIG values ('APL/ApplyPredictedValue', 'false',null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/AbsoluteExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveExplanationsCount', '0', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeExplanationsCount', '0', null);

call "apl_apply_example"(FUNC_HEADER, MODEL_TRAIN_BIN, APPLY_CONFIG,  'APL_SAMPLES','ADULT01', 'USER_APL','ADVANCED_SETTINGS_APPLY');
select * from "USER_APL"."ADVANCED_SETTINGS_APPLY";

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);
insert into APPLY_CONFIG values ('APL/ApplyPredictedValue', 'false',null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations', 'true', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/AbsoluteExplanationsCount', '0', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/PositiveExplanationsCount', '5', null);
insert into APPLY_CONFIG values ('APL/UnpivotedExplanations/NegativeExplanationsCount', '5', null);

call "apl_apply_example"(FUNC_HEADER, MODEL_TRAIN_BIN, APPLY_CONFIG,  'APL_SAMPLES','ADULT01', 'USER_APL','ADVANCED_SETTINGS_APPLY');
select * from "USER_APL"."ADVANCED_SETTINGS_APPLY";

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);
insert into APPLY_CONFIG values ('APL/ApplyPredictedValue', 'false',null);
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
insert into APPLY_CONFIG values ('APL/ApplyPredictedValue', 'false',null);
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
insert into APPLY_CONFIG values ('APL/ApplyPredictedValue', 'false',null);
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
insert into APPLY_CONFIG values ('APL/ApplyPredictedValue', 'false',null);
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
insert into APPLY_CONFIG values ('APL/ApplyPredictedValue', 'false',null);
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
insert into APPLY_CONFIG values ('APL/ApplyPredictedValue', 'false',null);
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


