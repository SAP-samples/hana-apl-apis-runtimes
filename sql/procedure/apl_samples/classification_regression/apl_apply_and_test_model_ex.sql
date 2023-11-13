-- ================================================================
-- APL_AREA, APPLY_MODEL_AND_TEST, using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(apl_createmodel_and_train_ex.sql)
-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';


-- Ouput table type: dataset
drop type ADULT01_T_OUT;
create type ADULT01_T_OUT as table (
    "KxIndex" INTEGER,
    "class" INTEGER,
    "rr_class" DOUBLE
);


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');


drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
-- TODO: insert training configuration parameters (to be defined)

drop table ADULT01_APPLY_TEST;
create column table ADULT01_APPLY_TEST like ADULT01_T_OUT;

drop table APPLY_TEST_LOG;
create column table APPLY_TEST_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table APPLY_MODEL_AND_TEST_BIN;
create column table APPLY_MODEL_AND_TEST_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table APPLY_TEST_INDICATORS;
create table APPLY_TEST_INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
select * from "USER_APL"."ADULT01_APPLY_TEST";
select * from "USER_APL"."APPLY_MODEL_AND_TEST_BIN";
select * from "USER_APL"."APPLY_TEST_LOG";
select * from "USER_APL"."APPLY_TEST_INDICATORS";
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from APPLY_CONFIG;            
    model_in = select * from MODEL_TRAIN_BIN;  

    "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL_AND_TEST"(:header, :model_in, :config,'APL_SAMPLES','ADULT01','USER_APL','ADULT01_APPLY_TEST', out_model,  out_log,out_indic);          
    insert into  "USER_APL"."APPLY_MODEL_AND_TEST_BIN" select * from :out_model;
    insert into  "USER_APL"."APPLY_TEST_LOG"           select * from :out_log;
    insert into  "USER_APL"."APPLY_TEST_INDICATORS"    select * from :out_indic;

	select * from "USER_APL"."ADULT01_APPLY_TEST";
	select * from "USER_APL"."APPLY_MODEL_AND_TEST_BIN";
	select * from "USER_APL"."APPLY_TEST_LOG";
	select * from "USER_APL"."APPLY_TEST_INDICATORS";
END;
