-- ================================================================
-- APL_AREA, EXPORT_VARIABLEDESCRIPTIONS
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

-- Assumption 3: There's a valid model (created by APL) in the MODEL_BIN table.
--               For instance, you have used apl_createmodel_and_train_bin_ex.sql before
--  @depend(apl_createmodel_and_train_ex.sql)

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------

connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#69');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table VARIABLE_DESC_OUT;
create table VARIABLE_DESC_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    modle_in = select * from MODEL_TRAIN_BIN;             

   "SAP_PA_APL"."sap.pa.apl.base::EXPORT_VARIABLEDESCRIPTIONS"(:header, :modle_in,  out_variable_desc);
    
    -- store result into table
	insert into  "USER_APL"."VARIABLE_DESC_OUT" select * from :out_variable_desc;

	-- show result
    select * from "USER_APL"."VARIABLE_DESC_OUT";
END;
