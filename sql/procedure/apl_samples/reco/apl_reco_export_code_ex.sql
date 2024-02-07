-- ================================================================
-- APL_AREA, EXPORT_APPLY_CODE_FOR_RECO, using a native format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid and trained model (created by APL) in the MODEL_SORTED, MODEL_NODES1, MODEL_NODES2, MODEL_LINKS tables.
--               For instance, you have used apl_create_reco_model_and_train_ex.sql before
--  @depend(apl_create_reco_model_and_train_ex.sql)

connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------



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

drop table EXPORT_RECO_SQL;
create table EXPORT_RECO_SQL like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.RESULT";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------

-- Export SQL for HANA 
drop table EXPORT_CONFIG;
create table EXPORT_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_DETAILED";
insert into EXPORT_CONFIG values ('APL/CodeType', 'HANA',null);
insert into EXPORT_CONFIG values ('APL/CodeKey', '"TransactionID"',null); --(use double quote to force case sensitivity if the table column name is not created in all caps)
insert into EXPORT_CONFIG values ('APL/CodeSpace', 'APL_SAMPLES.CUST_TRANSACTIONS',null);

DO BEGIN     
    header       = select * from FUNC_HEADER;             
    model        = select * from MODEL_RECO;            
    config       = select * from EXPORT_CONFIG;    

    "SAP_PA_APL"."sap.pa.apl.base::EXPORT_APPLY_CODE_FOR_RECO"(:header, :model, 'USER_APL','MODEL_NODES1','USER_APL','MODEL_NODES2','USER_APL','MODEL_LINKS', :config, :out_export);          

    -- store result into table
    insert into  "USER_APL"."EXPORT_RECO_SQL"   select * from :out_export;

    -- show result
    select * from "USER_APL"."EXPORT_RECO_SQL";

END;
