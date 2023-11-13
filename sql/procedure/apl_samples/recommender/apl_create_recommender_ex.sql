-- ================================================================
-- APL_AREA, CREATE_RECOMMENDER, there is no model generated
-- This script creates a recommender, which can be then used through APPLY_RECOMMENDER_TO_BASKET, APPLY_RECOMMENDER_TO_USER, RECO_APPLY_SQL and RECO_EXCLUDE_HISTORY_ADD_TOP
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

connect USER_APL password Password1;

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------

drop table FUNC_HEADER;
create COLUMN table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

drop table RECO_CONFIG;
create table RECO_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_DETAILED";
insert into RECO_CONFIG values ('APL/User', 'UserID', NULL);                      -- mandatory
insert into RECO_CONFIG values ('APL/Item', 'ItemPurchased', NULL);               -- mandatory
--insert into RECO_CONFIG values ('APL/Date', 'Date_PutInCaddy', NULL);             -- optional (default: NULL)
--insert into RECO_CONFIG values ('APL/StartDate', '2000-12-20 17:32:24', NULL);    -- optional (default: NULL)
--insert into RECO_CONFIG values ('APL/EndDate', '2001-03-26 17:32:24', NULL);      -- optional (default: NULL)
insert into RECO_CONFIG values ('APL/BestSeller', '50000', NULL);                 -- optional (default: 50000)
insert into RECO_CONFIG values ('APL/MinimumSupport', '2', NULL);                 -- optional (default: 2)
insert into RECO_CONFIG values ('APL/MinimumConfidence', '0.05', NULL);           -- optional (default: 0.05)
insert into RECO_CONFIG values ('APL/MinimumPredictivePower', '0.01', NULL);      -- optional (default: 0.0)
--insert into RECO_CONFIG values ('APL/MaxRules', '200', NULL);                     -- optional (default: NULL)

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

DROP TABLE RECOMMENDER_CUST_TRANSACTIONS;
-- The table will be created directly by the procedure if it does not already exist

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from RECO_CONFIG;            

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_RECOMMENDER"(:header, 'APL_SAMPLES','CUST_TRANSACTIONS', :config,'USER_APL', 'RECOMMENDER_CUST_TRANSACTIONS', out_summary);          

    -- store result into table
    insert into  "USER_APL"."SUMMARY"         select * from :out_summary;

    -- show result
    --select * from "USER_APL"."RECOMMENDER_CUST_TRANSACTIONS";
    select * from "USER_APL"."SUMMARY";
END;
