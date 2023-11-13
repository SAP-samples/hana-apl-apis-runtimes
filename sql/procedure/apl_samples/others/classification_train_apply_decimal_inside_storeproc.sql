-- @required(hanaMinimumVersion,2.0.30)
connect USER_APL password Password1;


DROP TABLE CENSUS_DECIMAL;
CREATE COLUMN TABLE CENSUS_DECIMAL("id" integer, "age" DECIMAL, "class" integer);

INSERT INTO CENSUS_DECIMAL
SELECT "id", "age" + "id" * power(10, -5), "class" 
FROM APL_SAMPLES.CENSUS;

DROP VIEW CENSUS_DECIMAL_ORDERED;
CREATE VIEW CENSUS_DECIMAL_ORDERED as
SELECT *
FROM CENSUS_DECIMAL
ORDER BY "id";


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

drop PROCEDURE  "apl_classification_train_apply_example";
CREATE PROCEDURE "apl_classification_train_apply_example" ()
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER AS
BEGIN
   declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
   declare create_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
   declare apply_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
   declare var_decs "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
   declare var_roles "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      

   :header.insert(('Oid', '#42'));
   :header.insert(('LogLevel', '8'));
   :header.insert(('ModelFormat', 'bin'));
   :header.insert(('CheckOperationConfig', 'true'));
   
   -- create a classification model
   :create_config.insert (('APL/ModelType', 'regression/classification',null));

   :var_roles.insert(('class', 'target', null, null, null));

   SAP_PA_APL."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :create_config, :var_decs,:var_roles, 'USER_APL','CENSUS_DECIMAL_ORDERED', :model, ?, ?, ?);
   
   -- get table defintion to apply the model
   SAP_PA_APL."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header,:model, :apply_config, 'USER_APL','CENSUS_DECIMAL_ORDERED', :table_type, ?);
   
   -- create apply_out table for definition
   "drop_table_if_exit"('USER_APL','APPLY_OUTPUT');
   SAP_PA_APL."sap.pa.apl.base::CREATE_TABLE_FROM_TABLE_TYPE"('USER_APL', 'APPLY_OUTPUT', :table_type );
   
   -- apply model
   SAP_PA_APL."sap.pa.apl.base::APPLY_MODEL"(:header,:model, :apply_config,'USER_APL','CENSUS_DECIMAL','USER_APL', 'APPLY_OUTPUT', ?,?);

END;

-- call example
call "apl_classification_train_apply_example"();

select * from "USER_APL"."APPLY_OUTPUT";
