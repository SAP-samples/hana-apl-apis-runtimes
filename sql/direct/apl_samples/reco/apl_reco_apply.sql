-- ================================================================
-- APL_AREA, APPLY_RECO_MODEL, using a native format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid trained model (created by APL) in the MODEL_SORTED, MODEL_NODES1, MODEL_NODES2, MODEL_LINKS tables. 
--               For instance you have used apl_create_reco_model_and_train.sql before.
--  @depend(apl_create_reco_model_and_train.sql)


-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

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
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
-- the AFL wrapper generator needs the signature of the expected stored proc
drop table APPLY_MODEL_SIGNATURE;
create column table APPLY_MODEL_SIGNATURE  like PROCEDURE_SIGNATURE_T;

insert into APPLY_MODEL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into APPLY_MODEL_SIGNATURE values (2, 'USER_APL','MODEL_NATIVE_T', 'IN');
insert into APPLY_MODEL_SIGNATURE values (3, 'USER_APL','MODEL_RECO_NODES1_T', 'IN');
insert into APPLY_MODEL_SIGNATURE values (4, 'USER_APL','MODEL_RECO_NODES2_T', 'IN');
insert into APPLY_MODEL_SIGNATURE values (5, 'USER_APL','MODEL_RECO_LINKS_T', 'IN');
insert into APPLY_MODEL_SIGNATURE values (6, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into APPLY_MODEL_SIGNATURE values (7, 'USER_APL','USER_T',          'IN');
insert into APPLY_MODEL_SIGNATURE values (8, 'USER_APL','RECO_SCORE_T',      'OUT');
insert into APPLY_MODEL_SIGNATURE values (9, 'USER_APL','OPERATION_LOG_T',    'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_APPLY_RECO_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','APPLY_RECO_MODEL','USER_APL', 'APLWRAPPER_APPLY_RECO_MODEL', APPLY_MODEL_SIGNATURE);


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');


drop table APPLY_CONFIG;
create table APPLY_CONFIG like OPERATION_CONFIG_T;
-- TODO: insert training configuration parameters (to be defined)
insert into APPLY_CONFIG values ('APL/Top', '5');                        -- optional (default: max)
insert into APPLY_CONFIG values ('APL/IncludeBestSellers', 'false');      -- optional (default: false)
insert into APPLY_CONFIG values ('APL/SkipAlreadyOwned', 'true');       -- optional (default: true)


drop table USER_APPLYIN;
create column table USER_APPLYIN like USER_T;
insert into USER_APPLYIN values ('23');

drop table USER_APPLYOUT;
create column table USER_APPLYOUT like RECO_SCORE_T;

drop table APPLY_LOG;
create column table APPLY_LOG like OPERATION_LOG_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
drop view MODEL_SORTED;
create view MODEL_SORTED AS SELECT *  from MODEL_RECO order by "ID" asc  ;
DO BEGIN     
    header       = select * from FUNC_HEADER;             
    model        = select * from MODEL_SORTED;            
    model_nodes1 = select * from MODEL_NODES1;            
    model_nodes2 = select * from MODEL_NODES2;            
    model_links  = select * from MODEL_LINKS;            
    config       = select * from APPLY_CONFIG;    
    apply_in     = select * from USER_APPLYIN;            

    APLWRAPPER_APPLY_RECO_MODEL(:header, :model, :model_nodes1, :model_nodes2, :model_links, :config, :apply_in, out_apply, out_log);          

    -- store result into table
    insert into  "USER_APL"."USER_APPLYOUT"   select * from :out_apply;
    insert into  "USER_APL"."APPLY_LOG"       select * from :out_log;

    -- show result
    select * from "USER_APL"."USER_APPLYOUT";
    select * from "USER_APL"."APPLY_LOG";
END;
