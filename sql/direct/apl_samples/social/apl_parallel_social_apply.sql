-- @required(hanaMinimumVersion,20SP0)
-- ================================================================
-- APL_AREA, APPLY_SOCIAL_MODEL, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid and trained model (created by APL) in the MODMOEL_SOCIAL table.
--               For instance, you have used apl_create_social_model_and_train_links_only.sql before
--  @depend(apl_create_social_model_and_train_links_only.sql)
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


drop type SOCIAL_SCORE_T;
create type SOCIAL_SCORE_T as table (
	"CALLER" NVARCHAR(10),
	"kxComIndex" INT,
	"sn_graph01_cm_idx" INT,
	"sn_graph01_cm_idx_1" INT,
	"sn_graph01_cm_idx_2" INT,
	"sn_graph01_cm_idx_3" INT,
	"sn_graph01_cm_c_off" INT,
	"sn_graph01_cm_c_off_1" INT,
	"sn_graph01_cm_c_off_2" INT,
	"sn_graph01_cm_c_off_3" INT,
	"sn_graph01_cm_r_off" DOUBLE,
	"sn_graph01_cm_r_off_1" DOUBLE,
	"sn_graph01_cm_r_off_2" DOUBLE,
	"sn_graph01_cm_r_off_3" DOUBLE,
	"sn_graph01_cm_rl" NVARCHAR(5000),
	"sn_graph01_cm_sz" INT,"sn_graph01_cm_sz_1" INT,
	"sn_graph01_cm_sz_2" INT,"sn_graph01_cm_sz_3" INT,
	"sn_graph01_i_dg" INT,"sn_graph01_o_dg" INT,
	"sn_graph01_i_w_dg" DOUBLE,"sn_graph01_o_w_dg" DOUBLE,
	"sn_graph01_sg" NVARCHAR(5000),"sn_graph01_i_c_off" DOUBLE,
	"sn_graph01_o_c_off" DOUBLE,"sn_graph01_i_r_off" DOUBLE,
	"sn_graph01_o_r_off" DOUBLE,"sn_graph01_tc" INT);

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
-- the AFL wrapper generator needs the signature of the expected stored proc
drop table CALL_SIGNATURE;
create table CALL_SIGNATURE   like PROCEDURE_SIGNATURE_T;
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
insert into CALL_SIGNATURE values (11, 'USER_APL','SOCIAL_SCORE_T',     'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_APPLY_SOCIAL_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA', 'PARALLEL_APPLY_SOCIAL_MODEL', 'USER_APL', 'APLWRAPPER_APPLY_SOCIAL_MODEL', CALL_SIGNATURE);



-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');

drop table APPLY_CONFIG;
create table APPLY_CONFIG like OPERATION_CONFIG_DETAILED_T;
insert into APPLY_CONFIG values ('APL/ApplyMode', 'Default_Mode', null);
-- TODO: insert apply configuration parameters (to be defined)

drop table SCHEMA_OUT;
create table SCHEMA_OUT like TABLE_TYPE_T;

drop table INPUT_DATA;
create table INPUT_DATA like APPLY_IN_CONTACT_EVENTS_T;
insert into INPUT_DATA values('6479988873',0);

drop table APPLY_OUT;
create table APPLY_OUT like SOCIAL_SCORE_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------

DO BEGIN     
    header             = select * from FUNC_HEADER;
    config             = select * from APPLY_CONFIG;    
	model              = select * from MODEL_SOCIAL order by "ID" asc  ;  
	model_nodes1       = select * from MODEL_SOCIAL_NODES1;  
	model_nodes2       = select * from MODEL_SOCIAL_NODES2;  
	model_links        = select * from MODEL_SOCIAL_LINKS;  
	model_communities  = select * from MODEL_SOCIAL_COMMUNITIES;  
	model_attributes1  = select * from MODEL_SOCIAL_ATTRIBUTES1;  
	model_attributes2  = select * from MODEL_SOCIAL_ATTRIBUTES2;  
	apply_in          = select * from INPUT_DATA;  
    
    call APLWRAPPER_APPLY_SOCIAL_MODEL(
        :header,
		:model,
	    :model_nodes1,
	    :model_nodes2,
	    :model_links,
	    :model_communities,
	    :model_attributes1,
	    :model_attributes2,
		:config,
        :apply_in,
        out_apply) WITH HINT(PARALLEL_BY_PARAMETER_PARTITIONS(p10));          

    -- store result into table
    insert into  "USER_APL"."APPLY_OUT"  select * from :out_apply;

    -- show result
	select * from "USER_APL"."APPLY_OUT";
END;
