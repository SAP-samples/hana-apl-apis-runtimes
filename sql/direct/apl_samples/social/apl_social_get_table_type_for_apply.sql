-- ================================================================
-- APL_AREA, GET_TABLE_TYPE_FOR_SOCIAL_APPLY, using a native format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid and trained model (created by APL) in the native MODEL
--               For instance, you have used apl_create_social_model_and_train_contact.sql before
--  @depend(apl_create_social_model_and_train_contact.sql)
-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

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

-- Only used for transaction graphs with projection, type is not important for other graphs
drop type MODEL_SOCIAL_ATTRIBUTES_T;
create type MODEL_SOCIAL_ATTRIBUTES_T as table (
    "DUMMY" NVARCHAR(1)
);

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
-- the AFL wrapper generator needs the signature of the expected stored proc
drop table CALL_SIGNATURE;
create column table CALL_SIGNATURE   like PROCEDURE_SIGNATURE_T;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_NATIVE_T',     'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','MODEL_SOCIAL_NODES1_T',     'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','MODEL_SOCIAL_NODES2_T',     'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','MODEL_SOCIAL_LINKS_T',     'IN');
insert into CALL_SIGNATURE values (6, 'USER_APL','MODEL_SOCIAL_COMMUNITIES_T',     'IN');
insert into CALL_SIGNATURE values (7, 'USER_APL','MODEL_SOCIAL_ATTRIBUTES_T',     'IN');
insert into CALL_SIGNATURE values (8, 'USER_APL','MODEL_SOCIAL_ATTRIBUTES_T',     'IN');
insert into CALL_SIGNATURE values (9, 'USER_APL','OPERATION_CONFIG_DETAILED_T', 'IN');
insert into CALL_SIGNATURE values (10, 'USER_APL','APPLY_IN_CONTACT_EVENTS_T',          'IN');
insert into CALL_SIGNATURE values (11, 'USER_APL','TABLE_TYPE_T',     'OUT');
insert into CALL_SIGNATURE values (12, 'USER_APL','OPERATION_LOG_T',    'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_GET_TABLE_TYPE_FOR_SOCIAL_APPLY');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA', 'GET_TABLE_TYPE_FOR_SOCIAL_APPLY', 'USER_APL', 'APLWRAPPER_GET_TABLE_TYPE_FOR_SOCIAL_APPLY', CALL_SIGNATURE);


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');

drop table APPLY_CONFIG;
create table APPLY_CONFIG like OPERATION_CONFIG_DETAILED_T;
insert into APPLY_CONFIG values ('APL/ApplyMode', 'Default_Mode',null);
-- TODO: insert apply configuration parameters (to be defined)

drop table SCHEMA_OUT;
create table SCHEMA_OUT like TABLE_TYPE_T;

drop table SCHEMA_LOG;
create table SCHEMA_LOG like OPERATION_LOG_T;

drop table INPUT_DATA;
create table INPUT_DATA like APPLY_IN_CONTACT_EVENTS_T;
--insert into INPUT_DATA values('6479988873','9057318773','SMS','2007-04-05 23:13:00',2281,0);

drop view SOCIAL_MODEL_SORTED;
create view SOCIAL_MODEL_SORTED AS SELECT *  from MODEL_SOCIAL order by "ID" asc  ;
-- select * from SOCIAL_MODEL_SORTED;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header             = select * from FUNC_HEADER;
    config             = select * from APPLY_CONFIG;    
	model              = select * from SOCIAL_MODEL_SORTED;  
	model_nodes1       = select * from MODEL_SOCIAL_NODES1;  
	model_nodes2       = select * from MODEL_SOCIAL_NODES2;  
	model_links        = select * from MODEL_SOCIAL_LINKS;  
	model_communities  = select * from MODEL_SOCIAL_COMMUNITIES;  
	model_attributes1  = select * from MODEL_SOCIAL_ATTRIBUTES1;  
	model_attributes2  = select * from MODEL_SOCIAL_ATTRIBUTES2;  
	appply_in          = select * from INPUT_DATA;  
    
    APLWRAPPER_GET_TABLE_TYPE_FOR_SOCIAL_APPLY(
        :header,
		:model,
	    :model_nodes1,
	    :model_nodes2,
	    :model_links,
	    :model_communities,
	    :model_attributes1,
	    :model_attributes2,
		:config,
        :appply_in,
        out_schema,
	    out_log);          

    -- store result into table
    insert into  "USER_APL"."SCHEMA_OUT"  select * from :out_schema;
    insert into  "USER_APL"."SCHEMA_LOG"  select * from :out_log;

    -- show result
	select * from "USER_APL"."SCHEMA_LOG";
	select * from "USER_APL"."SCHEMA_OUT";
END;

