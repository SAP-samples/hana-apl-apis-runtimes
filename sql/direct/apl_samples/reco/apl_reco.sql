-- ================================================================
-- APL_AREA, RECOMMEND
-- Description :
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).


-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

drop type CUST_TRANSACTIONS_T;
create type CUST_TRANSACTIONS_T as table (
    "UserID" INTEGER,
    "ItemPurchased" NVARCHAR(18),
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
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
-- the AFL wrapper generator needs the signature of the expected stored proc
drop table RECO_SIGNATURE;
create table RECO_SIGNATURE like PROCEDURE_SIGNATURE_T;
insert into RECO_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into RECO_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into RECO_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_T', 'IN');
insert into RECO_SIGNATURE values (4, 'USER_APL','CUST_TRANSACTIONS_T', 'IN');
insert into RECO_SIGNATURE values (5, 'USER_APL','USER_T', 'IN');
insert into RECO_SIGNATURE values (6, 'USER_APL','RECO_SCORE_T', 'OUT');
insert into RECO_SIGNATURE values (7, 'USER_APL','OPERATION_LOG_T', 'OUT');
insert into RECO_SIGNATURE values (8, 'USER_APL','SUMMARY_T', 'OUT');
insert into RECO_SIGNATURE values (9, 'USER_APL','INDICATORS_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_RECO');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','RECOMMEND','USER_APL', 'APLWRAPPER_RECO', RECO_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

-- Model config
drop table RECO_CONFIG;
create table RECO_CONFIG like OPERATION_CONFIG_T;
insert into RECO_CONFIG values ('APL/User', 'UserID');                  -- mandatory
insert into RECO_CONFIG values ('APL/Item', 'ItemPurchased');           -- mandatory
insert into RECO_CONFIG values ('APL/Weight', 'Quantity');              -- optional
insert into RECO_CONFIG values ('APL/Date', 'Date_PutInCaddy');         -- optional
insert into RECO_CONFIG values ('APL/BestSeller', '1000000');           -- optional (default: 50000)
insert into RECO_CONFIG values ('APL/MinimumSupport', '4');             -- optional (default: 2)
insert into RECO_CONFIG values ('APL/MinimumConfidence', '0.1');        -- optional (default: 0.05)
insert into RECO_CONFIG values ('APL/MinimumPredictivePower', '0.01');  -- optional (default: disable)
insert into RECO_CONFIG values ('APL/MaxTopNodes', '1000');             -- optional (default: 100000)
-- Apply configuration
--insert into RECO_CONFIG values ('APL/Top', '6');                        -- optional (default: max)
insert into RECO_CONFIG values ('APL/IncludeBestSellers', 'true');      -- optional (default: false)
insert into RECO_CONFIG values ('APL/SkipAlreadyOwned', 'false');       -- optional (default: true)

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
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
create table OPERATION_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header       = select * from FUNC_HEADER;             
    config       = select * from RECO_CONFIG;    
    var_desc     = select * from VARIABLE_DESC;              
    dataset      = select * from APL_SAMPLES.CUST_TRANSACTIONS;  
    user         = select * from USER_APL.CUST_TO_SCORE;

    APLWRAPPER_RECO(:header, :config, :var_desc, :dataset, :user, out_score, out_log, out_summ, out_indic);          

    -- store result into table
    insert into  "USER_APL"."RECO_SCORE"    select * from :out_score;
    insert into  "USER_APL"."OPERATION_LOG" select * from :out_log;
    insert into  "USER_APL"."SUMMARY"       select * from :out_summ;
    insert into  "USER_APL"."INDICATORS"    select * from :out_indic;

    -- show result
    select * from "USER_APL"."RECO_SCORE" order by "UserID";
    select * from "USER_APL"."OPERATION_LOG";
    select * from "USER_APL"."SUMMARY";
    select * from "USER_APL"."INDICATORS";
END;
