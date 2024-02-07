-- ================================================================
-- APL_AREA, GET_VARIABLE_INDICATORS, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

-- Assumption 2: There's a valid and trained model (created by APL) in the MODEL_TRAIN_BIN table.
--               For instance, you have used apl_createmodel_and_train_ex.sql before
--  @depend(apl_createmodel_and_train_ex.sql)

connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table USER_APL.FUNC_HEADER;
create table USER_APL.FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into USER_APL.FUNC_HEADER values ('Oid', '#69');


drop table USER_APL.INDICATORS_CONFIG;
create table USER_APL.INDICATORS_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";

DO BEGIN     
    header   = select * from FUNC_HEADER;       
    modle_in = select * from MODEL_TRAIN_BIN;             
    config   = select * from INDICATORS_CONFIG;

    "SAP_PA_APL"."sap.pa.apl.base::GET_VARIABLE_INDICATORS"(:header, :modle_in, :config, out_indicators);
    
    -- store result into table
	insert into  "USER_APL"."INDICATORS" select * from :out_indicators;

	-- show result
    select * from "USER_APL"."INDICATORS";
END;
