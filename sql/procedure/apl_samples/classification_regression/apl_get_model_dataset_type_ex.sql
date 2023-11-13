-- ================================================================
-- APL_AREA, GET_MODEL_DATASET_TYPES, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(apl_createmodel_and_train_ex.sql)

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

drop table OPERATION_CONFIG;
create table OPERATION_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";

drop table TRAINING_SIGNATURE;
create table TRAINING_SIGNATURE like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.TABLE_TYPE";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    modle_in = select * from MODEL_TRAIN_BIN;             
    config    = select * from OPERATION_CONFIG;          

    "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_DATASET_TYPES"(:header, :modle_in, :config, out_schema);
    
    -- store result into table
	insert into  "USER_APL"."TRAINING_SIGNATURE" select * from :out_schema;

	-- show result
    select * from "USER_APL"."TRAINING_SIGNATURE";
END;
