-- ================================================================
-- APL_AREA, CREATE_SOCIAL_MODEL_AND_TRAIN, using a native format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).

-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

-- Input table type: dataset
drop type CONTACT_EVENTS_T;
create type CONTACT_EVENTS_T as table (
	"CALLER" NVARCHAR(10),
	"CALLEE" NVARCHAR(10),
	 "CLASS" NVARCHAR(5),
	 "DATE" LONGDATE,
	"DURATION" INTEGER
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

-- Only used for transaction graphs with projection, type is not important for other graphs
drop type MODEL_SOCIAL_ATTRIBUTES_T;
create type MODEL_SOCIAL_ATTRIBUTES_T as table (
    "DUMMY" NVARCHAR(1)
);

drop table CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE;
create column table CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE  like PROCEDURE_SIGNATURE_T;
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_DETAILED_T', 'IN');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_OID_T', 'IN');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_WITH_COMPOSITES_OID_T', 'IN');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (5, 'USER_APL','GRAPH_FILTERS_T', 'IN');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (6, 'USER_APL','GRAPH_POST_PROCESSINGS_T', 'IN');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (7, 'USER_APL','CONTACT_EVENTS_T', 'IN');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (8, 'USER_APL','MODEL_NATIVE_T', 'OUT');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (9, 'USER_APL','MODEL_SOCIAL_NODES1_T', 'OUT');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (10, 'USER_APL','MODEL_SOCIAL_NODES2_T', 'OUT');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (11, 'USER_APL','MODEL_SOCIAL_LINKS_T', 'OUT');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (12, 'USER_APL','MODEL_SOCIAL_COMMUNITIES_T', 'OUT');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (13, 'USER_APL','MODEL_SOCIAL_ATTRIBUTES_T', 'OUT');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (14, 'USER_APL','MODEL_SOCIAL_ATTRIBUTES_T', 'OUT');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (15, 'USER_APL','OPERATION_LOG_T', 'OUT');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (16, 'USER_APL','SUMMARY_T', 'OUT');
insert into CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE values (17, 'USER_APL','GRAPH_INDICATORS_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_CREATE_SOCIAL_MODEL_AND_TRAIN');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','CREATE_SOCIAL_MODEL_AND_TRAIN','USER_APL', 'APLWRAPPER_CREATE_SOCIAL_MODEL_AND_TRAIN', CREATE_SOCIAL_MODEL_AND_TRAIN_SIGNATURE);


drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

drop table SOCIAL_CONFIG;
create table SOCIAL_CONFIG like OPERATION_CONFIG_DETAILED_T;
insert into SOCIAL_CONFIG values ('APL/ModelType', 'social',null);
insert into SOCIAL_CONFIG values ('APL/Graph', 'nearestneighbors','graph01');
/** Begin Common **/
insert into SOCIAL_CONFIG values ('APL/SourceNode', 'CALLER','graph01');
insert into SOCIAL_CONFIG values ('APL/TargetNode', 'CALLEE','graph01');

insert into SOCIAL_CONFIG values ('APL/MaxConnections', '50000','graph01');
insert into SOCIAL_CONFIG values ('APL/Date', 'DATE','graph01');
--insert into SOCIAL_CONFIG values ('APL/StartDate', '2007-04-26 00:00:00','graph01');
--insert into SOCIAL_CONFIG values ('APL/EndDate', '2007-06-20 00:00:00','graph01');
/** End Common **/

/** Begin Specifics (Neighbors)**/
insert into SOCIAL_CONFIG values ('APL/Distance', 'DURATION','graph01');
insert into SOCIAL_CONFIG values ('APL/MaxNeighbors', '42','graph01');
/** End Specifics (Neighbors)**/



-- select * from "APL_SAMPLES"."CONTACT_EVENTS" order by date desc;

/** Begin configure filters **/
drop table SOCIAL_GRAPH_FILTERS;
create table SOCIAL_GRAPH_FILTERS like GRAPH_FILTERS_T;

-- insert into SOCIAL_GRAPH_FILTERS values ('graph01','CALLER','accept','7945321222');
-- insert into SOCIAL_GRAPH_FILTERS values ('graph01','CALLER','accept','4169042981');
-- insert into SOCIAL_GRAPH_FILTERS values ('graph01','CALLEE','discard','6134491824');
-- insert into SOCIAL_GRAPH_FILTERS values ('graph01','CALLEE','discard','6047659299');
-- insert into SOCIAL_GRAPH_FILTERS values ('graph01','DURATION','minimum','0');
-- insert into SOCIAL_GRAPH_FILTERS values ('graph01','DURATION','maximum','1000');

/** End configure filters **/

/** Begin Post Processing **/
drop table SOCIAL_POST_PROCESSINGS;
create table SOCIAL_POST_PROCESSINGS like GRAPH_POST_PROCESSINGS_T;

-- Communities detection

insert into SOCIAL_POST_PROCESSINGS values ('CM_1', 'communities','GraphName','graph01');
insert into SOCIAL_POST_PROCESSINGS values ('CM_1', 'communities','MaxIterations','11');
insert into SOCIAL_POST_PROCESSINGS values ('CM_1', 'communities','Epsilon','4.2E-5');


/*
-- Megahub detection
insert into SOCIAL_POST_PROCESSINGS values ('MEGA_1', 'megahub','GraphName','graph01');
--insert into SOCIAL_POST_PROCESSINGS values ('MEGA_1', 'megahub','DeviationFactor','12');
insert into SOCIAL_POST_PROCESSINGS values ('MEGA_1', 'megahub','Threshold','40000');
insert into SOCIAL_POST_PROCESSINGS values ('MEGA_1', 'megahub','Population','First');
*/

-- Nodes pairing
/*
insert into SOCIAL_POST_PROCESSINGS values ('N_1', 'pairing','FirstGraph','graph01');
insert into SOCIAL_POST_PROCESSINGS values ('N_1', 'pairing','SecondGraph','graph01');
insert into SOCIAL_POST_PROCESSINGS values ('N_1', 'pairing','TopN','69');
insert into SOCIAL_POST_PROCESSINGS values ('N_1', 'pairing','CountThreshold','7');

insert into SOCIAL_POST_PROCESSINGS values ('N_1', 'pairing','PairingGraph','xxx');
insert into SOCIAL_POST_PROCESSINGS values ('N_1', 'pairing','PairingType','Independence_Ratio');
insert into SOCIAL_POST_PROCESSINGS values ('N_1', 'pairing','RatioThreshold','0.7');
insert into SOCIAL_POST_PROCESSINGS values ('N_1', 'pairing','WeightedRatio','false');
insert into SOCIAL_POST_PROCESSINGS values ('N_1', 'pairing','IncludeNeighbors','false');
*/


/** End Post Processing **/



drop table MODEL_SOCIAL;
create table MODEL_SOCIAL like MODEL_NATIVE_T;

drop table VARIABLE_DESC;
create table VARIABLE_DESC like VARIABLE_DESC_OID_T;

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like VARIABLE_ROLES_WITH_COMPOSITES_OID_T;

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
create table OPERATION_LOG like OPERATION_LOG_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

drop table INDICATORS;
create table INDICATORS like GRAPH_INDICATORS_T;

DO BEGIN     
    header           = select * from FUNC_HEADER;
    config           = select * from SOCIAL_CONFIG;    
    var_desc         = select * from VARIABLE_DESC;              
    var_roles        = select * from VARIABLE_ROLES;              
	graph_filters    = select * from SOCIAL_GRAPH_FILTERS;
	post_processings = select * from SOCIAL_POST_PROCESSINGS;
    dataset          = select * from APL_SAMPLES.CONTACT_EVENTS;  
    
    APLWRAPPER_CREATE_SOCIAL_MODEL_AND_TRAIN(
        :header,
		:config, 
		:var_desc, 
		:var_roles, 
		:graph_filters, 
		:post_processings, 
		:dataset, 
		out_model,
	    out_model_nodes1,
	    out_model_nodes2,
	    out_model_links,
	    out_model_communities,
	    out_model_attributes1,
	    out_model_attributes2,
        out_log,
	    out_summary,
	    out_indicators);          

    -- store result into table
    insert into  "USER_APL"."MODEL_SOCIAL"                select * from :out_model;
    insert into  "USER_APL"."MODEL_SOCIAL_NODES1"         select * from :out_model_nodes1;
    insert into  "USER_APL"."MODEL_SOCIAL_NODES2"         select * from :out_model_nodes2;
    insert into  "USER_APL"."MODEL_SOCIAL_LINKS"          select * from :out_model_links;
    insert into  "USER_APL"."MODEL_SOCIAL_COMMUNITIES"    select * from :out_model_communities;
    insert into  "USER_APL"."MODEL_SOCIAL_ATTRIBUTES1"    select * from :out_model_attributes1;
    insert into  "USER_APL"."MODEL_SOCIAL_ATTRIBUTES2"    select * from :out_model_attributes2;
    insert into  "USER_APL"."OPERATION_LOG"               select * from :out_log;
    insert into  "USER_APL"."SUMMARY"                     select * from :out_summary;
    insert into  "USER_APL"."INDICATORS"                  select * from :out_indicators;

    -- show result
	select * from MODEL_SOCIAL_NODES1;
	select * from MODEL_SOCIAL_NODES2;
	select * from MODEL_SOCIAL_LINKS;
	select * from MODEL_SOCIAL_COMMUNITIES;
	select * from MODEL_SOCIAL;	 
	select * from SUMMARY;
	select * from INDICATORS;
	select * from OPERATION_LOG;
END;
