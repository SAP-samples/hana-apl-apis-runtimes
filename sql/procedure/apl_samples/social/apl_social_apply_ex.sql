-- ================================================================
-- APL_AREA, APPLY_SOCIAL_MODEL, using a native format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

-- Assumption 3: There's a valid and trained model (created by APL) in the MODEL_SOCIAL table.
--               For instance, you have used apl_create_social_model_and_train_links_only_ex.sql before
--  @depend(apl_create_social_model_and_train_links_only_ex.sql)
-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- Input table type: dataset
drop type APPLY_IN_CONTACT_EVENTS_T;
create type APPLY_IN_CONTACT_EVENTS_T as table (
	"CALLER" NVARCHAR(10),
	"KXCOMINDEX" INTEGER
);

-- This type depends on the model type and the apply settings used, use GET_SOCIAL_TABLE_TYPE_FOR_APPLY to get its format
drop type SOCIAL_SCORE_T;
create type SOCIAL_SCORE_T as table (
	"CALLER" NVARCHAR(10),
	"kxComIndex" BIGINT,
	"sn_graph01_cm_idx" BIGINT,
	"sn_graph01_cm_idx_1" BIGINT,
	"sn_graph01_cm_idx_2" BIGINT,
	"sn_graph01_cm_idx_3" BIGINT,
	"sn_graph01_cm_c_off" BIGINT,
	"sn_graph01_cm_c_off_1" BIGINT,
	"sn_graph01_cm_c_off_2" BIGINT,
	"sn_graph01_cm_c_off_3" BIGINT,
	"sn_graph01_cm_r_off" DOUBLE,
	"sn_graph01_cm_r_off_1" DOUBLE,
	"sn_graph01_cm_r_off_2" DOUBLE,
	"sn_graph01_cm_r_off_3" DOUBLE,
	"sn_graph01_cm_rl" NVARCHAR(5000),
	"sn_graph01_cm_sz" BIGINT,
	"sn_graph01_cm_sz_1" BIGINT,
	"sn_graph01_cm_sz_2" BIGINT,
	"sn_graph01_cm_sz_3" BIGINT,
	"sn_graph01_i_dg" BIGINT,
	"sn_graph01_o_dg" BIGINT,
	"sn_graph01_i_w_dg" DOUBLE,
	"sn_graph01_o_w_dg" DOUBLE,
	"sn_graph01_sg" NVARCHAR(5000),
	"sn_graph01_i_c_off" DOUBLE,
	"sn_graph01_o_c_off" DOUBLE,
	"sn_graph01_i_r_off" DOUBLE,
	"sn_graph01_o_r_off" DOUBLE,
	"sn_graph01_tc" BIGINT
);

-- KxNodes1
drop type MODEL_SOCIAL_NODES1_T;
create type MODEL_SOCIAL_NODES1_T as table (
	"node" NVARCHAR(10)
);

-- KxNodes2 
-- not used here
drop type MODEL_SOCIAL_NODES2_T;
create type MODEL_SOCIAL_NODES2_T as table (
	"node" NVARCHAR(255) 
);

-- KxLinks
drop type MODEL_SOCIAL_LINKS_T;
create type MODEL_SOCIAL_LINKS_T as table (
    "GRAPH_NAME" NVARCHAR(255),
    "WEIGHT" DOUBLE,
    "KXNODEFIRST" NVARCHAR(10), 
    "KXNODEFIRST_2" NVARCHAR(10)
);

--KxCommunities1
drop type MODEL_SOCIAL_COMMUNITIES_T;
create type MODEL_SOCIAL_COMMUNITIES_T as table (
	"GRAPH_NAME" NVARCHAR(255),
    "KXNODEFIRST" NVARCHAR(10),
    "COM_INDEX" INTEGER,
    "COM_INTRA" INTEGER,    
    "COM_EXTRA" INTEGER    
);

drop type MODEL_SOCIAL_ATTRIBUTES_T;
create type MODEL_SOCIAL_ATTRIBUTES_T as table (
    "GRAPH_NAME" NVARCHAR(255),
    "UserID" INTEGER,
    "generation_id" INTEGER, 
    "SOURCE_NODES" NVARCHAR(255),  -- same type than ItemPurchased
	"HEAD_NODE_ID" INTEGER,
	"TAIL_NODE_ID" INTEGER
);


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNCHEADER;
create table FUNCHEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNCHEADER values ('Oid', '#42');
insert into FUNCHEADER values ('LogLevel', '8');


drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into APPLY_CONFIG values ('APL/ApplyMode', 'Default_Mode', null);
-- TODO: insert apply configuration parameters (to be defined)

drop table INPUT_DATA;
create table INPUT_DATA like APPLY_IN_CONTACT_EVENTS_T;
insert into INPUT_DATA values ('6479988873', 0);

drop table APPLY_LOG;
create table APPLY_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table APPLY_OUT;
create table APPLY_OUT like SOCIAL_SCORE_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header             = select * from FUNC_HEADER;
    config             = select * from APPLY_CONFIG;    
	model              = select * from MODEL_SOCIAL;  
	appply_in          = select * from INPUT_DATA;  
    
    "SAP_PA_APL"."sap.pa.apl.base::APPLY_SOCIAL_MODEL"(
        :header,
		:model,
	    'USER_APL','MODEL_SOCIAL_NODES1',
	    'USER_APL','MODEL_SOCIAL_NODES2',
	    'USER_APL','MODEL_SOCIAL_LINKS',
	    'USER_APL','MODEL_SOCIAL_COMMUNITIES',
	    'USER_APL','MODEL_SOCIAL_ATTRIBUTES1',
	    'USER_APL','MODEL_SOCIAL_ATTRIBUTES2',
		:config,
	    'USER_APL','INPUT_DATA',
	    'USER_APL','APPLY_OUT',
	    out_log);          

    -- store result into table
    insert into  "USER_APL"."APPLY_LOG"  select * from :out_log;

    -- show result
	select * from "USER_APL"."APPLY_LOG";
	select * from "USER_APL"."APPLY_OUT";
END;
