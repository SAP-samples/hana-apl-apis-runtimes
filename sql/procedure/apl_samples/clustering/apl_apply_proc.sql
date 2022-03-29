-- @configSQL
-- ================================================================
-- This script demonstrates the application create a apply procedure 
-- with creation of apply out table
-- Assumption 1: The users & privileges have been created & granted (see apl_admin_ex.sql).
connect USER_APL password Password1;

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

drop PROCEDURE  "apl_apply_example";
CREATE PROCEDURE "apl_apply_example" (
    IN  header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER",
    IN  model  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID",
    IN  config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED",
    IN  apply_in_schema    VARCHAR  (127),
    IN  apply_in_table     VARCHAR  (127),
    IN  apply_out_schema   VARCHAR  (127),
    IN  apply_out_table    VARCHAR  (127)
)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER AS
BEGIN
    "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header, :model, :config, apply_in_schema, :apply_in_table,out_schema, out_log);
    "drop_table_if_exit"(:apply_out_schema, :apply_out_table);
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_TABLE_FROM_TABLE_TYPE"(:apply_out_schema, :apply_out_table, :out_schema);
    "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL"(:header,  :model, :config, :apply_in_schema, :apply_in_table, :apply_out_schema, :apply_out_table , out_apply_log, out_sum);
END;

drop PROCEDURE  "apl_apply_example_2";
CREATE PROCEDURE "apl_apply_example_2" (
    IN  header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER",
    IN  model  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID",
    IN  config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED",
    IN  apply_in_schema    VARCHAR  (127),
    IN  apply_in_table     VARCHAR  (127),
    IN  apply_out_schema   VARCHAR  (127),
    IN  apply_out_table    VARCHAR  (127),
    OUT out_apply_log   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG",
    OUT out_apply_sum   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY"
)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER AS
BEGIN
    "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header, :model, :config, :apply_in_schema, :apply_in_table,out_schema, out_log);
    "drop_table_if_exit"(:apply_out_schema, :apply_out_table);
    "SAP_PA_APL"."sap.pa.apl.base::CREATE_TABLE_FROM_TABLE_TYPE"(:apply_out_schema, :apply_out_table, :out_schema);
    "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL"(:header,  :model, :config, :apply_in_schema, :apply_in_table, :apply_out_schema, :apply_out_table , out_apply_log, out_apply_sum);
END;
