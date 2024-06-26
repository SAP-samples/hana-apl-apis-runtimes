-- ================================================================
-- APL_AREA, CREATE_RECO_MODEL_AND_TRAIN, using a native format for the model
-- This script creates a recommendation model, guesses its description, trains it and generates the code for similar products recommendation.
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).


-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

-- Input table type: dataset
drop type MOVIES_ATTRIBUTES_T;
create type MOVIES_ATTRIBUTES_T as table (
	"FILM" NVARCHAR(50),
	"ATTRIBUTE" NVARCHAR(80)
);

-- KxNodes1  
drop type MODEL_RECO_NODES1_T;
create type MODEL_RECO_NODES1_T as table (
	"node" NVARCHAR(80) -- must be of the same SQL type as the attribute column (ATTRIBUTE here)
);

-- KxNodes2 
drop type MODEL_RECO_NODES2_T;
create type MODEL_RECO_NODES2_T as table (
	"node" NVARCHAR(50) -- must be of the same SQL type as the Item column (FILM here)
);

-- KxLinks
drop type MODEL_RECO_LINKS_T;
create type MODEL_RECO_LINKS_T as table (
    "GRAPH_NAME" NVARCHAR(255),
    "WEIGHT" DOUBLE,
    "KXNODEFIRST" NVARCHAR(80), -- must be of the same SQL type as the attribute column (ATTRIBUTE here)
    "KXNODESECOND" NVARCHAR(50), -- must be of the same SQL type as the Item column (FILM here)
    "KXNODESECOND_2" NVARCHAR(50) -- must be of the same SQL type as the Item column (FILM here)
);
  
-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
-- the AFL wrapper generator needs the signature of the expected stored proc
drop table CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE;
create table CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_T', 'IN');
insert into CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE values (4, 'USER_APL','MOVIES_ATTRIBUTES_T', 'IN');
insert into CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE values (5, 'USER_APL','MODEL_NATIVE_T', 'OUT');
insert into CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE values (6, 'USER_APL','MODEL_RECO_NODES1_T', 'OUT');
insert into CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE values (7, 'USER_APL','MODEL_RECO_NODES2_T', 'OUT');
insert into CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE values (8, 'USER_APL','MODEL_RECO_LINKS_T', 'OUT');
insert into CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE values (9, 'USER_APL','OPERATION_LOG_T', 'OUT');
insert into CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE values (10, 'USER_APL','SUMMARY_T', 'OUT');
insert into CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE values (11, 'USER_APL','INDICATORS_T', 'OUT');
insert into CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE values (12, 'USER_APL','RESULT_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_CREATE_RECO_MODEL_AND_TRAIN');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','CREATE_RECO_MODEL_AND_TRAIN','USER_APL', 'APLWRAPPER_CREATE_RECO_MODEL_AND_TRAIN', CREATE_RECO_MODEL_AND_TRAIN_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

drop table RECO_CONFIG;
create table RECO_CONFIG like OPERATION_CONFIG_T;
insert into RECO_CONFIG values ('APL/ModelType', 'recommendation');

insert into RECO_CONFIG values ('APL/User', 'ATTRIBUTE');      -- mandatory
insert into RECO_CONFIG values ('APL/Item', 'FILM');           -- mandatory

insert into RECO_CONFIG values ('APL/RecommendationType', 'similarity');  -- optional (default: standard)
insert into RECO_CONFIG values ('APL/RecommendProcName', 'USER_APL.RECOMMEND_SIMILAR_MOVIES');  -- optional (default: RECOMMEND_SIMILAR_ITEM)
insert into RECO_CONFIG values ('APL/RecoLinksTable', '"USER_APL"."MODEL_LINKS"');  -- optional (default: KxLinks1)

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_T;
-- let this table empty to use guess variables

drop table MODEL_RECO;
create table MODEL_RECO like MODEL_NATIVE_T;

drop table MODEL_NODES1;
create table MODEL_NODES1 like MODEL_RECO_NODES1_T;

drop table MODEL_NODES2;
create table MODEL_NODES2 like MODEL_RECO_NODES2_T;

drop table MODEL_LINKS;
create table MODEL_LINKS like MODEL_RECO_LINKS_T;

drop table OPERATION_LOG;
create table OPERATION_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like INDICATORS_T;


drop table EXPORT_RECO_SQL;
create table EXPORT_RECO_SQL like RESULT_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;             
    config   = select * from RECO_CONFIG;            
    var_desc = select * from VARIABLE_DESC;              
    dataset  = select * from APL_SAMPLES.MOVIES_ATTRIBUTES;  

    APLWRAPPER_CREATE_RECO_MODEL_AND_TRAIN(:header, :config, :var_desc, :dataset, out_model,  out_model_nodes1, out_model_nodes2, out_model_links, out_log, out_sum, out_indic, out_export_sql);          

    -- store result into table
    insert into  "USER_APL"."MODEL_RECO"      select * from :out_model;
    insert into  "USER_APL"."MODEL_NODES1"    select * from :out_model_nodes1;
    insert into  "USER_APL"."MODEL_NODES2"    select * from :out_model_nodes2;
    insert into  "USER_APL"."MODEL_LINKS"     select * from :out_model_links;
    insert into  "USER_APL"."OPERATION_LOG"   select * from :out_log;
    insert into  "USER_APL"."SUMMARY"         select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"      select * from :out_indic;
    insert into  "USER_APL"."EXPORT_RECO_SQL" select * from :out_export_sql;

    -- show result
    select * from "USER_APL"."MODEL_NODES1";
    select * from "USER_APL"."MODEL_NODES2";
    select * from "USER_APL"."MODEL_LINKS";
    select * from "USER_APL"."EXPORT_RECO_SQL";
END;
