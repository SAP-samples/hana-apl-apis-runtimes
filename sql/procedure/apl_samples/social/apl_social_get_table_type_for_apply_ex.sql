-- ================================================================
-- APL_AREA, GET_TABLE_TYPE_FOR_APPLY, using a binary format for the model
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
insert into APPLY_CONFIG values ('APL/ApplyMode', 'Default_Mode',null);
-- TODO: insert apply configuration parameters (to be defined)

drop table SCHEMA_OUT;
create table SCHEMA_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.TABLE_TYPE";

drop table SCHEMA_LOG;
create table SCHEMA_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table INPUT_DATA;
create table INPUT_DATA like APPLY_IN_CONTACT_EVENTS_T;
--insert into INPUT_DATA values('6479988873','9057318773','SMS','2007-04-05 23:13:00',2281,0);

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
	DECLARE model "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_NATIVE";
    header             = select * from FUNC_HEADER;
    config             = select * from APPLY_CONFIG;    
	model              = select * from MODEL_SOCIAL;
    
    "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_SOCIAL_APPLY"(
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
        out_schema,
	    out_log);          

    -- store result into table
    insert into  "USER_APL"."SCHEMA_OUT"  select * from :out_schema;
    insert into  "USER_APL"."SCHEMA_LOG"  select * from :out_log;

    -- show result
	select * from "USER_APL"."SCHEMA_LOG";
	select * from "USER_APL"."SCHEMA_OUT";
END;

