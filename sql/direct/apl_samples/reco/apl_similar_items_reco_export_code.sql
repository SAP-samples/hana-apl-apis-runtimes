-- ================================================================
-- APL_AREA, EXPORT_APPLY_CODE_FOR_RECO, using a native format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid and trained model (created by APL) in the MODEL_SORTED, MODEL_NODES1, MODEL_NODES2, MODEL_LINKS tables.
--               For instance, you have used apl_create_similar_item_reco_model_and_train.sql before
--  @depend(apl_create_similar_item_reco_model_and_train.sql)

connect USER_APL password Password1;

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------

drop table EXPORT_APPLY_CODE_SIGNATURE;
create column table EXPORT_APPLY_CODE_SIGNATURE like PROCEDURE_SIGNATURE_T;

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
    
insert into EXPORT_APPLY_CODE_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into EXPORT_APPLY_CODE_SIGNATURE values (2, 'USER_APL','MODEL_NATIVE_T', 'IN');
insert into EXPORT_APPLY_CODE_SIGNATURE values (3, 'USER_APL','MODEL_RECO_NODES1_T', 'IN');
insert into EXPORT_APPLY_CODE_SIGNATURE values (4, 'USER_APL','MODEL_RECO_NODES2_T', 'IN');
insert into EXPORT_APPLY_CODE_SIGNATURE values (5, 'USER_APL','MODEL_RECO_LINKS_T', 'IN');
insert into EXPORT_APPLY_CODE_SIGNATURE values (6, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into EXPORT_APPLY_CODE_SIGNATURE values (7, 'USER_APL','RESULT_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_EXPORT_APPLY_CODE_FOR_RECO');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','EXPORT_APPLY_CODE_FOR_RECO','USER_APL', 'APLWRAPPER_EXPORT_APPLY_CODE_FOR_RECO', EXPORT_APPLY_CODE_SIGNATURE);


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;

drop table EXPORT_RECO_SQL;
create table EXPORT_RECO_SQL like RESULT_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------

-- Export SQL for HANA 
drop table EXPORT_CONFIG;
create table EXPORT_CONFIG like OPERATION_CONFIG_T;

insert into EXPORT_CONFIG values ('APL/RecommendationType', 'similarity');  -- optional (default: standard)
insert into EXPORT_CONFIG values ('APL/RecommendProcName', 'RECOMMEND_SIMILAR_FILM');  -- optional (default: RECOMMEND_SIMILAR_ITEM)
insert into EXPORT_CONFIG values ('APL/RecoLinksTable', 'MODEL_LINKS');  -- optional (default: KxLinks1)

drop view MODEL_SORTED;
create view MODEL_SORTED AS SELECT *  from MODEL_RECO order by "ID" asc  ;
DO BEGIN     
    header       = select * from FUNC_HEADER;             
    model        = select * from MODEL_SORTED;            
    model_nodes1 = select * from MODEL_NODES1;            
    model_nodes2 = select * from MODEL_NODES2;            
    model_links  = select * from MODEL_LINKS;            
    config       = select * from EXPORT_CONFIG;    

    APLWRAPPER_EXPORT_APPLY_CODE_FOR_RECO(:header, :model, :model_nodes1, :model_nodes2, :model_links, :config, :out_export);          

    -- store result into table
    insert into  "USER_APL"."EXPORT_RECO_SQL"   select * from :out_export;

    -- show result
    select * from "USER_APL"."EXPORT_RECO_SQL";

END;