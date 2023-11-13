-- ================================================================
-- APL_AREA, APPLY_MODEL, using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(apl_createmodel_and_train_ex.sql)

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------
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

drop table ADULT01_APPLY;
create column table ADULT01_APPLY like ADULT01_T_OUT;

drop table APPLY_LOG;
create column table APPLY_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create column table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header       = select * from FUNC_HEADER;             
    model_in     = select * from MODEL_TRAIN_BIN; 	           
    apply_config = select * from APPLY_CONFIG; 	           

    "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL"(:header, :model_in, :apply_config, 'APL_SAMPLES','ADULT01', 'USER_APL','ADULT01_APPLY' , out_apply_log, out_sum);

    -- store result into table
	insert into  "USER_APL"."APPLY_LOG"       select * from :out_apply_log;
	insert into  "USER_APL"."SUMMARY"         select * from :out_sum;

	-- show result
	select * from "USER_APL"."ADULT01_APPLY";
	select * from "USER_APL"."APPLY_LOG";
END;
