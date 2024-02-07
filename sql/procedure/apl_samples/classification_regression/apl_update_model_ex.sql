-- ================================================================
-- APL_AREA, UPDATE_MODEL
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

drop table USER_APL.UPDATE_CONFIG;
create table USER_APL.UPDATE_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";

drop table USER_APL.MODEL_UPDATED_BIN;
create table USER_APL.MODEL_UPDATED_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header           = select * from FUNC_HEADER;             
    config           = select * from UPDATE_CONFIG;  
    model_in         = select * from MODEL_TRAIN_BIN;

    "SAP_PA_APL"."sap.pa.apl.base::UPDATE_MODEL"(:header, :model_in, :config, :out_model);
 
    -- store result into table
    insert into  "USER_APL"."MODEL_UPDATED_BIN"            select * from :out_model;

	-- show result
    select * from "USER_APL"."MODEL_UPDATED_BIN";
END;
