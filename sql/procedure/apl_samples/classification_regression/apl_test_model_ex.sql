-- ================================================================
-- APL_AREA, TEST_MODEL, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types_ex.sql).
-- Assumption 3: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(apl_createmodel_and_train_ex.sql)

-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

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


drop table TEST_CONFIG;
create table TEST_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";

drop table TEST_MODEL_BIN;
create table TEST_MODEL_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table TEST_LOG;
create column table TEST_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table TEST_INDICATORS;
create table TEST_INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";


-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;
	model_in = select * from MODEL_TRAIN_BIN;
    test_config = select * from TEST_CONFIG;            

	"SAP_PA_APL"."sap.pa.apl.base::TEST_MODEL"(:header, :model_in, :test_config,'APL_SAMPLES','ADULT01', out_model, out_test_log, out_test_indic);
    
    -- store result into table
    insert into  "USER_APL"."TEST_MODEL_BIN"   select * from :out_model;
    insert into  "USER_APL"."TEST_LOG"         select * from :out_test_log;
    insert into  "USER_APL"."TEST_INDICATORS"  select * from :out_test_indic;

	-- show result
	select * from "USER_APL"."TEST_MODEL_BIN";
	select * from "USER_APL"."TEST_LOG";
	select * from "USER_APL"."TEST_INDICATORS";
END;
