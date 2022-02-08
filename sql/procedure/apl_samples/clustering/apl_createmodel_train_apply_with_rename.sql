-- ================================================================
-- APL_AREA, CREATE_MODEL_AND_TRAIN, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

--SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';


drop procedure "drop_table_if_exit";
create procedure  "drop_table_if_exit" (
 IN  in_schema    VARCHAR  (127),  -- Schema Name holding table to be dropped
 IN  in_table   VARCHAR  (127)    -- Table name to be dropped
)
LANGUAGE SQLSCRIPT
AS
BEGIN
  declare tab_exists smallint := 0;
  select count(*) into tab_exists from TABLES where schema_name = :in_schema and table_name = :in_table;
  
  IF tab_exists > 0 THEN
    exec 'drop table "' || :in_schema||'"."'||:in_table ||'"';
  END IF;
END;

drop PROCEDURE  "apl_train_apply_example";
CREATE PROCEDURE "apl_train_apply_example" (
    IN  header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER",
    IN  train_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED",
    IN  var_desc  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID",
    IN  var_role  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID",
    IN  apply_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED",
    IN  apply_in_schema    VARCHAR  (127),
    IN  apply_in_table     VARCHAR  (127),
    IN  apply_out_schema   VARCHAR  (127),
    IN  apply_out_table    VARCHAR  (127)
)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER AS
BEGIN
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :train_config, :var_desc,:var_role,  :apply_in_schema,:apply_in_table,model,out_log,out_sum,out_indic);    
    "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header, :model, :apply_config,  :apply_in_schema, :apply_in_table,out_schema, out_log);
    "drop_table_if_exit"(:apply_out_schema, :apply_out_table);
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_TABLE_FROM_TABLE_TYPE"(:apply_out_schema, :apply_out_table, :out_schema);
    "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL"(:header,  :model, :apply_config, :apply_in_schema, :apply_in_table, :apply_out_schema, :apply_out_table , out_apply_log, out_sum);
END;


drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table CREATE_AND_TRAIN_CONFIG;
create table CREATE_AND_TRAIN_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_DETAILED";
insert into CREATE_AND_TRAIN_CONFIG values ('APL/ModelType', 'clustering',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/CalculateSQLExpressions', 'false',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/NbClustersMin', '4',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/NbClustersMax', '5',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/Distance', 'SystemDetermined',null);


drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- let this table empty to use guess variables
--INSERT INTO VARIABLE_DESC VALUES (0, 'id', 'integer', 'nominal', 1, 0, '', '', '', '#42');
--INSERT INTO VARIABLE_DESC VALUES (1, 'age', 'integer', 'continuous', 0, 0, '', '', '', '#42');

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
INSERT INTO VARIABLE_ROLES VALUES ('class', 'target', null, null, '#42');
--INSERT INTO VARIABLE_ROLES VALUES ('id', 'skip', null, null, '#42');

drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_DETAILED";
-- TODO: insert apply configuration parameters (to be defined)
insert into APPLY_CONFIG values ('APL/ApplyExtraMode', 'No Extra', null);
insert into APPLY_CONFIG values ('Protocols/Default/Variables/kc_class/SpaceName', 'CLUSTER_ID', null);


call "apl_train_apply_example"(FUNC_HEADER,CREATE_AND_TRAIN_CONFIG, VARIABLE_DESC, VARIABLE_ROLES, APPLY_CONFIG, 'APL_SAMPLES','CENSUS', 'USER_APL','CENSUS_K2S_APPLY_SD');
select * from "USER_APL"."CENSUS_K2S_APPLY_SD";
