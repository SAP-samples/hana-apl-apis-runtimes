-- ================================================================
-- APL_AREA, PUBLISH_MODEL
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

-- Assumption 2: There's a valid and trained model (created by APL) in the MODEL_TRAIN_BIN table.
--               For instance, you have used apl_createmodel_and_train_ex.sql before
--  @depend(apl_createmodel_and_train_ex.sql)

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table USER_APL.FUNC_HEADER;
create table USER_APL.FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into USER_APL.FUNC_HEADER values ('Oid', '#69');

drop table USER_APL.PUBLISH_CONFIG;
create table USER_APL.PUBLISH_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into USER_APL.PUBLISH_CONFIG values ('APL/ModelName', 'Train Model',null);
insert into USER_APL.PUBLISH_CONFIG values ('APL/ModelComment', 'Published from APL',null);
insert into USER_APL.PUBLISH_CONFIG values ('APL/ModelSpaceName', '"USER_APL"."MODELS"',null);

-- Warning: These drop/create statements are going to remove an existing and working version of the KXADMIN table
-- In a regular use case (not this sample), the KXADMIN table already exists and it's managed by the InfiniteInsight modeler tool.
drop table USER_APL.KXADMIN;
create table USER_APL.KXADMIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.ADMIN";

drop table USER_APL.MODELS;
create table USER_APL.MODELS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_NATIVE";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header           = select * from FUNC_HEADER;             
    model_in         = select * from MODEL_TRAIN_BIN;
    config           = select * from PUBLISH_CONFIG;  
    kxadmin          = select * from USER_APL.KXADMIN;  
    
    "SAP_PA_APL"."sap.pa.apl.base::PUBLISH_MODEL"(:header, :model_in, :config, :kxadmin, out_kxadmin, out_models, out_summ);

    -- store result into table
    insert into  "USER_APL"."KXADMIN"           select * from :out_kxadmin;
    insert into  "USER_APL"."MODELS"            select * from :out_models;
    insert into  "USER_APL"."SUMMARY"           select * from :out_summ;

	-- show result
    select * from USER_APL.KXADMIN;
    select * from USER_APL.MODELS;
    select * from SUMMARY;
END;
