-- ================================================================
-- APL_AREA, APPLY_RECO_MODEL, using a native format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model (created by APL) in the MODEL_SORTED, MODEL_NODES1, MODEL_NODES2, MODEL_LINKS tables. 
--               For instance you have used apl_create_reco_model_and_train_ex.sql before.
--  @depend(apl_create_reco_model_and_train_ex.sql)

-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

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

drop type RECO_SCORE_T;
create type RECO_SCORE_T as table (
    "UserID" INTEGER,
    "ItemPurchased" NVARCHAR(128),
    "sn_rec_rule_id" INTEGER,
    "sn_rec_kxReco" NVARCHAR(128),
    "sn_rec_source"  NVARCHAR(128),
    "sn_rec_score" DOUBLE
);

drop type USER_T;
create type USER_T as table (
    "UserID" INTEGER -- must be of the same SQL type as the User column (UserID here)
);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');


drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_DETAILED";
-- TODO: insert training configuration parameters (to be defined)
insert into APPLY_CONFIG values ('APL/Top', '5',null);                        -- optional (default: max)
insert into APPLY_CONFIG values ('APL/IncludeBestSellers', 'false',null);      -- optional (default: false)
insert into APPLY_CONFIG values ('APL/SkipAlreadyOwned', 'true',null);       -- optional (default: true)


drop table USER_APPLYIN;
create column table USER_APPLYIN like USER_T;
insert into USER_APPLYIN values ('23');

drop table USER_APPLYOUT;
create column table USER_APPLYOUT like RECO_SCORE_T;

drop table APPLY_LOG;
create column table APPLY_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header       = select * from FUNC_HEADER;             
    model        = select * from MODEL_RECO;            
    config       = select * from APPLY_CONFIG;    

    "SAP_PA_APL"."sap.pa.apl.base::APPLY_RECO_MODEL"(:header, :model,  'USER_APL','MODEL_NODES1', 'USER_APL', 'MODEL_NODES2', 'USER_APL','MODEL_LINKS', :config,'USER_APL','USER_APPLYIN', 'USER_APL','USER_APPLYOUT', out_log);          

    -- store result into table
    insert into  "USER_APL"."APPLY_LOG"       select * from :out_log;

    -- show result
    select * from "USER_APL"."USER_APPLYOUT";
    select * from "USER_APL"."APPLY_LOG";
END;
