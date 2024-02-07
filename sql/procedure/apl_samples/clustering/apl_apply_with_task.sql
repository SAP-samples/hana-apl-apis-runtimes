-- @required(hanaMaximumVersion,2.99.999)
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
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');
insert into FUNC_HEADER values ('MaxTasks', '2');

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------
--  Apply the model to get the decision, probability and contributions via the advanced apply settings
-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'Advanced Apply Settings',null);

-- Copy Variables
insert into APPLY_CONFIG values ('APL/ApplyCopyVariables','education;occupation',null);
-- Export constants
insert into APPLY_CONFIG values ('APL/ApplyConstant/BuildDate','export',null);
insert into APPLY_CONFIG values ('APL/ApplyConstant/ApplyDate','export',null);
insert into APPLY_CONFIG values ('APL/ApplyConstant/ModelName','export',null);
insert into APPLY_CONFIG values ('APL/ApplyConstant/ModelVersion','export',null);


call "apl_apply_example"(FUNC_HEADER, MODEL_TRAIN_BIN, APPLY_CONFIG, 'APL_SAMPLES','ADULT01', 'USER_APL','ADVANCED_SETTINGS_APPLY');
select * from "USER_APL"."ADVANCED_SETTINGS_APPLY";

