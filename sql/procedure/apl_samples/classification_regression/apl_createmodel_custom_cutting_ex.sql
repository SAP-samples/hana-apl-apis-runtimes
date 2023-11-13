-- ================================================================
-- APL_AREA, CREATE_MODEL, using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin_ex.sql).

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#69');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table CREATE_CONFIG;
create table CREATE_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into CREATE_CONFIG values ('APL/ModelType', 'regression/classification', null);
-- enable the custom cutting strategy 
insert into CREATE_CONFIG values ('APL/UseCustomCuttingStrategy', 'true', null);

drop table MODEL_BIN;
create table MODEL_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table VARIABLE_DESC_OUT;
create table VARIABLE_DESC_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";


-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from CREATE_CONFIG;  
	
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL"(:header, :config, 'APL_SAMPLES','ADULT01',out_model,out_var_desc);

    -- store result into table
    insert into  "USER_APL"."MODEL_BIN"          select * from :out_model;
    insert into  "USER_APL"."VARIABLE_DESC_OUT"  select * from :out_var_desc;

	-- show result
	select * from "USER_APL"."MODEL_BIN";
	select * from "USER_APL"."VARIABLE_DESC_OUT";
END;
