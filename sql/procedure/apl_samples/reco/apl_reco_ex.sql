-- ================================================================
-- APL_AREA, RECOMMEND
-- Description :
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).



-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

drop type CUST_TRANSACTIONS_T;
create type CUST_TRANSACTIONS_T as table (
    "UserID" INTEGER,
    "ItemPurchased" NVARCHAR(128),
    "Date_PutInCaddy" DATETIME,
    "Quantity" INTEGER,
    "TransactionID" INTEGER
);

drop type USER_T;
create type USER_T as table (
    "UserID" INTEGER
);

-- --------------------------------------------------------------------------
-- Create table type for the RECOMMEND output
-- --------------------------------------------------------------------------

drop type RECO_SCORE_T;
create type RECO_SCORE_T as table (
    "UserID" INTEGER,
    "ItemPurchased" NVARCHAR(128),
    "sn_rec_rule_id" INTEGER,
    "sn_rec_kxReco" NVARCHAR(128),
    "sn_rec_source"  NVARCHAR(128),
    "sn_rec_score" DOUBLE
);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

-- Model config
drop table RECO_CONFIG;
create table RECO_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_DETAILED";
insert into RECO_CONFIG values ('APL/User', 'UserID',null);                  -- mandatory
insert into RECO_CONFIG values ('APL/Item', 'ItemPurchased',null);           -- mandatory
insert into RECO_CONFIG values ('APL/Weight', 'Quantity',null);              -- optional
insert into RECO_CONFIG values ('APL/Date', 'Date_PutInCaddy',null);         -- optional
insert into RECO_CONFIG values ('APL/BestSeller', '1000000',null);           -- optional (default: 50000)
insert into RECO_CONFIG values ('APL/MinimumSupport', '4',null);             -- optional (default: 2)
insert into RECO_CONFIG values ('APL/MinimumConfidence', '0.1',null);        -- optional (default: 0.05)
insert into RECO_CONFIG values ('APL/MinimumPredictivePower', '0.01',null);  -- optional (default: disable)
insert into RECO_CONFIG values ('APL/MaxTopNodes', '1000',null);             -- optional (default: 100000)
-- Apply configuration
--insert into RECO_CONFIG values ('APL/Top', '6');                        -- optional (default: max)
insert into RECO_CONFIG values ('APL/IncludeBestSellers', 'true',null);      -- optional (default: false)
insert into RECO_CONFIG values ('APL/SkipAlreadyOwned', 'false',null);       -- optional (default: true)

drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- let this table empty to use guess variables


drop table CUST_TO_SCORE;
create table CUST_TO_SCORE like USER_T;
-- no data from CUST_TO_SCORE means that the APL internally considers all users present in the transactional data
--insert into CUST_TO_SCORE values ('23');
--insert into CUST_TO_SCORE values ('24');
--insert into CUST_TO_SCORE values ('33');
--insert into CUST_TO_SCORE values ('75');

drop table RECO_SCORE;
create table RECO_SCORE like RECO_SCORE_T;

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header       = select * from FUNC_HEADER;             
    config       = select * from RECO_CONFIG;    
    var_desc     = select * from VARIABLE_DESC;              

    "SAP_PA_APL"."sap.pa.apl.base::RECOMMEND"(:header, :config, :var_desc,  'APL_SAMPLES','CUST_TRANSACTIONS', 'USER_APL','CUST_TO_SCORE', 'USER_APL','RECO_SCORE', out_log, out_summ, out_indic);          

    -- store result into table
    insert into  "USER_APL"."OPERATION_LOG" select * from :out_log;
    insert into  "USER_APL"."SUMMARY"       select * from :out_summ;
    insert into  "USER_APL"."INDICATORS"    select * from :out_indic;

    -- show result
    select * from "USER_APL"."RECO_SCORE" order by "UserID";
    select * from "USER_APL"."OPERATION_LOG";
    select * from "USER_APL"."SUMMARY";
    select * from "USER_APL"."INDICATORS";
END;
