-- ================================================================
-- APL_AREA, CREATE_SOCIAL_MODEL_AND_TRAIN, using a native format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).


-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

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

drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

drop table SOCIAL_CONFIG;
create table SOCIAL_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into SOCIAL_CONFIG values ('APL/ModelType', 'social',null);
insert into SOCIAL_CONFIG values ('APL/Graph', 'link','graph01');
/** Begin Common **/
insert into SOCIAL_CONFIG values ('APL/LinkType', 'directed','graph01');
insert into SOCIAL_CONFIG values ('APL/SourceNode', 'CALLER','graph01');
insert into SOCIAL_CONFIG values ('APL/TargetNode', 'CALLEE','graph01');

insert into SOCIAL_CONFIG values ('APL/MaxConnections', '50000','graph01');
insert into SOCIAL_CONFIG values ('APL/Date', 'DATE','graph01');
--insert into SOCIAL_CONFIG values ('APL/StartDate', '2007-04-26 00:00:00','graph01');
--insert into SOCIAL_CONFIG values ('APL/EndDate', '2007-06-20 00:00:00','graph01');
/** End Common **/

/** Begin Specifics (Link-Only)**/
insert into SOCIAL_CONFIG values ('APL/Weight', 'DURATION','graph01');
/** End Specifics (Link-Only)**/

drop table SOCIAL_GRAPH_FILTERS;
create table SOCIAL_GRAPH_FILTERS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.GRAPH_FILTERS";

-- insert into SOCIAL_GRAPH_FILTERS values ('graph01','CALLER','accept','7945321222');
-- insert into SOCIAL_GRAPH_FILTERS values ('graph01','CALLER','accept','4169042981');
-- insert into SOCIAL_GRAPH_FILTERS values ('graph01','CALLEE','discard','6134491824');
-- insert into SOCIAL_GRAPH_FILTERS values ('graph01','CALLEE','discard','6047659299');
-- insert into SOCIAL_GRAPH_FILTERS values ('graph01','DURATION','minimum','0');
-- insert into SOCIAL_GRAPH_FILTERS values ('graph01','DURATION','maximum','1000');

drop table SOCIAL_POST_PROCESSINGS;
create table SOCIAL_POST_PROCESSINGS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.GRAPH_POST_PROCESSINGS";

-- Communities detection

insert into SOCIAL_POST_PROCESSINGS values ('CM_1', 'communities','GraphName','graph01');
insert into SOCIAL_POST_PROCESSINGS values ('CM_1', 'communities','MaxIterations','11');
insert into SOCIAL_POST_PROCESSINGS values ('CM_1', 'communities','Epsilon','4.2E-5');


drop table MODEL_SOCIAL;
create table MODEL_SOCIAL like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_NATIVE";

drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";


drop table MODEL_SOCIAL_NODES1;
create table MODEL_SOCIAL_NODES1 like MODEL_SOCIAL_NODES1_T;

drop table MODEL_SOCIAL_NODES2;
create table MODEL_SOCIAL_NODES2 like MODEL_SOCIAL_NODES2_T;

drop table MODEL_SOCIAL_LINKS;
create table MODEL_SOCIAL_LINKS like MODEL_SOCIAL_LINKS_T;

drop table MODEL_SOCIAL_COMMUNITIES;
create table MODEL_SOCIAL_COMMUNITIES like MODEL_SOCIAL_COMMUNITIES_T;

drop table MODEL_SOCIAL_ATTRIBUTES1;
create table MODEL_SOCIAL_ATTRIBUTES1 like MODEL_SOCIAL_ATTRIBUTES_T;

drop table MODEL_SOCIAL_ATTRIBUTES2;
create table MODEL_SOCIAL_ATTRIBUTES2 like MODEL_SOCIAL_ATTRIBUTES_T;

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.GRAPH_INDICATORS";
DO BEGIN     
    header           = select * from FUNC_HEADER;
    config           = select * from SOCIAL_CONFIG;    
    var_desc         = select * from VARIABLE_DESC;              
    var_roles        = select * from VARIABLE_ROLES;              
	graph_filters    = select * from SOCIAL_GRAPH_FILTERS;
	post_processings = select * from SOCIAL_POST_PROCESSINGS;
    dataset          = select * from APL_SAMPLES.CONTACT_EVENTS;  
    
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_SOCIAL_MODEL_AND_TRAIN"(
        :header,
		:config, 
		:var_desc, 
		:var_roles, 
		:graph_filters, 
		:post_processings, 
		'APL_SAMPLES', 'CONTACT_EVENTS', 
		out_model,
	    'USER_APL','MODEL_SOCIAL_NODES1',
	    'USER_APL','MODEL_SOCIAL_NODES2',
	    'USER_APL','MODEL_SOCIAL_LINKS',
	    'USER_APL','MODEL_SOCIAL_COMMUNITIES',
	    'USER_APL','MODEL_SOCIAL_ATTRIBUTES1',
	    'USER_APL','MODEL_SOCIAL_ATTRIBUTES2',
        out_log,
	    out_summary,
	    out_indicators);          

    -- store result into table
    insert into  "USER_APL"."MODEL_SOCIAL"                select * from :out_model;
    insert into  "USER_APL"."OPERATION_LOG"               select * from :out_log;
    insert into  "USER_APL"."SUMMARY"                     select * from :out_summary;
    insert into  "USER_APL"."INDICATORS"                  select * from :out_indicators;

    -- show result
	select * from MODEL_SOCIAL_NODES1;
	select * from MODEL_SOCIAL_LINKS;
	select * from MODEL_SOCIAL_COMMUNITIES;
    select * from MODEL_SOCIAL_ATTRIBUTES1;
    select * from MODEL_SOCIAL_ATTRIBUTES2;
	select * from MODEL_SOCIAL;	 
	select * from SUMMARY;
	select * from INDICATORS;
	select * from OPERATION_LOG;
END;

