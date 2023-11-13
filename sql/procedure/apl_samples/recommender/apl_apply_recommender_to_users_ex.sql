-- ================================================================
-- APL_AREA, APPLY_RECOMMENDER_TO_USERS, there is no model generated
-- This script uses a recommender to generate recommendations for users
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid recommender (created by APL) in the RECOMMENDER_CUST_TRANSACTIONS table. 
--               For instance you have used apl_create_recommender_ex.sql before.
--  @depend(apl_create_recommender_ex.sql)

connect USER_APL password Password1;

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------

drop table FUNC_HEADER;
create COLUMN table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

DROP TABLE RECO_CONFIG;
CREATE  TABLE RECO_CONFIG LIKE "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_DETAILED";
insert into RECO_CONFIG values ('APL/Top', '5', NULL);                              -- optional (default: NULL)
insert into RECO_CONFIG values ('APL/SkipAlreadyOwned', 'true', NULL);              -- optional (default: true)
insert into RECO_CONFIG values ('APL/Metric', 'CONFIDENCE', NULL);                  -- optional (default: CONFIDENCE) (values: CONFIDENCE, SUPPORT, KI, LIFT, COSINE, ADDED_VALUE)
insert into RECO_CONFIG values ('APL/FillWithBestSellers', 'false', NULL);          -- optional (default: false)
insert into RECO_CONFIG values ('APL/User', 'UserID', NULL);                        -- mandatory
insert into RECO_CONFIG values ('APL/Item', 'ItemPurchased', NULL);                 -- mandatory
--insert into RECO_CONFIG values ('APL/Date', 'Date_PutInCaddy', NULL);               -- optional (default: NULL)
--insert into RECO_CONFIG values ('APL/StartDate', '2000-12-20 17:32:24', NULL);      -- optional (default: NULL)
--insert into RECO_CONFIG values ('APL/EndDate', '2001-03-26 17:32:24', NULL);        -- optional (default: NULL)

-- The user list MUST be available in a column named "UserID"
DROP TABLE USERS_CUST;
CREATE COLUMN TABLE USERS_CUST ("UserID" Integer);
INSERT INTO USERS_CUST VALUES (728);
INSERT INTO USERS_CUST VALUES (65);

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

-- Result will be available in the table "RECOMMENDATIONS_FOR_BASKET" of the current schema
-- The table will be created directly by the procedure if it does not already exist
DROP TABLE RECOMMENDATIONS_FOR_USERS;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from RECO_CONFIG;            

    "SAP_PA_APL"."sap.pa.apl.base::APPLY_RECOMMENDER_TO_USERS"(:header,'USER_APL', 'RECOMMENDER_CUST_TRANSACTIONS', :config,'APL_SAMPLES', 'CUST_TRANSACTIONS', 'USER_APL', 'USERS_CUST', 'USER_APL', 'RECOMMENDATIONS_FOR_USERS', out_summary);          

    -- store result into table
    insert into  "USER_APL"."SUMMARY"         select * from :out_summary;

    -- show result
    -- select * from "USER_APL"."RECOMMENDATIONS_FOR_USERS";
    select * from "USER_APL"."SUMMARY";
END;
