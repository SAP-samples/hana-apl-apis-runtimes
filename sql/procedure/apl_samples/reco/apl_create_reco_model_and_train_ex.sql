-- ================================================================
-- APL_AREA, CREATE_RECO_MODEL_AND_TRAIN, using a native format for the model
-- This script creates a model, guesses its description and trains it
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).


-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- Input table type: dataset
drop type CUST_TRANSACTIONS_T;
create type CUST_TRANSACTIONS_T as table (
    "UserID" INTEGER,
    "ItemPurchased" NVARCHAR(128),
    "Date_PutInCaddy" DATETIME,
    "Quantity" INTEGER,
    "TransactionID" INTEGER
);

-- KxNodes1  
drop type MODEL_RECO_NODES1_T;
create type MODEL_RECO_NODES1_T as table (
	"node" INT -- must be of the same SQL type as the User column (UserID here)
);

-- KxNodes2 
drop type MODEL_RECO_NODES2_T;
create type MODEL_RECO_NODES2_T as table (
	"node" NVARCHAR(255) -- must be of the same SQL type as the Item column (ItemPurchased here)
);

-- KxLinks
drop type MODEL_RECO_LINKS_T;
create type MODEL_RECO_LINKS_T as table (
    "GRAPH_NAME" NVARCHAR(255),
    "WEIGHT" DOUBLE,
    "KXNODEFIRST" INT, -- must be of the same SQL type as the User column (UserID here)
    "KXNODESECOND" NVARCHAR(255), -- must be of the same SQL type as the Item column (ItemPurchased here)
    "KXNODESECOND_2" NVARCHAR(255) -- must be of the same SQL type as the Item column (ItemPurchased here)
);
  

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

drop table RECO_CONFIG;
create table RECO_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_DETAILED";
insert into RECO_CONFIG values ('APL/ModelType', 'recommendation',null);

insert into RECO_CONFIG values ('APL/User', 'UserID',null);                  -- mandatory
insert into RECO_CONFIG values ('APL/Item', 'ItemPurchased',null);           -- mandatory
insert into RECO_CONFIG values ('APL/Weight', 'Quantity',null);              -- optional
insert into RECO_CONFIG values ('APL/Date', 'Date_PutInCaddy',null);         -- optional
insert into RECO_CONFIG values ('APL/BestSeller', '11111000000',null);           -- optional (default: 50000)
insert into RECO_CONFIG values ('APL/MinimumSupport', '4',null);             -- optional (default: 2)
insert into RECO_CONFIG values ('APL/MinimumConfidence', '0.1',null);        -- optional (default: 0.05)
insert into RECO_CONFIG values ('APL/MinimumPredictivePower', '0.01',null);  -- optional (default: disable)
insert into RECO_CONFIG values ('APL/MaxTopNodes', '1000',null);             -- optional (default: 100000)

drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- let this table empty to use guess variables

drop table MODEL_RECO;
create table MODEL_RECO like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_NATIVE";

drop table MODEL_NODES1;
create table MODEL_NODES1 like MODEL_RECO_NODES1_T;

drop table MODEL_NODES2;
create table MODEL_NODES2 like MODEL_RECO_NODES2_T;

drop table MODEL_LINKS;
create table MODEL_LINKS like MODEL_RECO_LINKS_T;

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
    header   = select * from FUNC_HEADER;             
    config   = select * from RECO_CONFIG;            
    var_desc = select * from VARIABLE_DESC;              

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_RECO_MODEL_AND_TRAIN"(:header, :config, :var_desc, 'APL_SAMPLES','CUST_TRANSACTIONS', out_model, 'USER_APL','MODEL_NODES1','USER_APL', 'MODEL_NODES2', 'USER_APL','MODEL_LINKS', out_log, out_sum, out_indic,out_export_sql);          

    -- store result into table
    insert into  "USER_APL"."MODEL_RECO"      select * from :out_model;
    insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;
    insert into  "USER_APL"."SUMMARY"         select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"      select * from :out_indic;

    -- show result
    select * from "USER_APL"."MODEL_RECO";
    select * from "USER_APL"."MODEL_NODES1";
    select * from "USER_APL"."MODEL_NODES2";
    select * from "USER_APL"."MODEL_LINKS";
END;
