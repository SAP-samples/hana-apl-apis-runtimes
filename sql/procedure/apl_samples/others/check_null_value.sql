-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

drop table "DATASET";
create table "DATASET" as (  
SELECT 
"age", 
"workclass", 
to_double("fnlwgt" / .100) as  "fnlwgt",
"education", 
"education-num", 
"marital-status", 
"occupation", 
"relationship", 
"race", 
"sex", 
to_real("capital-gain" / .100) as  "capital-gain",
to_decimal("capital-loss", 10, 3) as "capital-loss", 
"hours-per-week",
"native-country", 
ADD_DAYS (CURRENT_DATE,"hours-per-week")  as "date",
"class" FROM "APL_SAMPLES"."ADULT01"
);

drop table "DATASET_WITH_NULL";
create table "DATASET_WITH_NULL" as ( select *  from DATASET);

UPDATE "DATASET_WITH_NULL" SET "age" = null  WHERE "age" =  65;
UPDATE "DATASET_WITH_NULL" SET "workclass" = null  WHERE "workclass" =  '?';
UPDATE "DATASET_WITH_NULL" SET "fnlwgt" = null  WHERE "fnlwgt" =  1933660.0;
UPDATE "DATASET_WITH_NULL" SET "capital-gain" = null  WHERE "capital-gain" =  24070.0;
UPDATE "DATASET_WITH_NULL" SET "capital-loss" = null  WHERE "capital-loss" =  0;
UPDATE "DATASET_WITH_NULL" SET "date" = null  WHERE "hours-per-week" = 1;

DO BEGIN
    declare ERROR condition for SQL_ERROR_CODE 10001;
    declare count_null integer;
    declare missing_value integer;
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare debrief_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";      
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      
    declare out_model "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";      
    declare out_log   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";      
    declare out_sum   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";      
    declare out_debrief_metric "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";      
    declare out_debrief_property "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";      
 

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '8'));
    :header.insert(('ModelFormat', 'bin'));

    :config.insert(('APL/ModelType', 'regression/classification',null));

    :var_role.insert(('class', 'target', null, null, null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN_DEBRIEF"(:header, :config, :var_desc,:var_role, 'USER_APL','DATASET_WITH_NULL',out_model,out_log,out_sum,out_debrief_metric,out_debrief_property);

    -- Dump Statistics Report
    var_data = select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_Variables"(:out_debrief_property, :out_debrief_metric);
    select * from :var_data;
   
    select COUNT(*)               into count_null    from "DATASET_WITH_NULL"  WHERE "age" is null;
    select "Missing Value Weight" into missing_value from :var_data where "Variable" = 'age';
    if ( :count_null  !=  :missing_value  ) then
	   signal ERROR set MESSAGE_TEXT = 'Wrong Missing Value for age' ;
	end if;       
   
    select COUNT(*)               into count_null    from "DATASET_WITH_NULL"  WHERE "workclass" is null;
    select "Missing Value Weight" into missing_value from :var_data where "Variable" = 'workclass';
    if ( :count_null  !=  :missing_value  ) then
	   signal ERROR set MESSAGE_TEXT = 'Wrong Missing Value for workclass' ;
	end if;       
   
    select COUNT(*)               into count_null    from "DATASET_WITH_NULL"  WHERE "fnlwgt" is null;
    select "Missing Value Weight" into missing_value from :var_data where "Variable" = 'fnlwgt';
    if ( :count_null  !=  :missing_value  ) then
	   signal ERROR set MESSAGE_TEXT = 'Wrong Missing Value for fnlwgt' ;
	end if;       
   
    select COUNT(*)               into count_null    from "DATASET_WITH_NULL"  WHERE "capital-gain" is null;
    select "Missing Value Weight" into missing_value from :var_data where "Variable" = 'capital-gain';
    if ( :count_null  !=  :missing_value  ) then
	   signal ERROR set MESSAGE_TEXT = 'Wrong Missing Value for capital-gain' ;
	end if;    

    select COUNT(*)               into count_null    from "DATASET_WITH_NULL"  WHERE "capital-loss" is null;
    select "Missing Value Weight" into missing_value from :var_data where "Variable" = 'capital-loss';
    if ( :count_null  !=  :missing_value  ) then
	   signal ERROR set MESSAGE_TEXT = 'Wrong Missing Value for capital-loss' ;
	end if;  

    select COUNT(*)               into count_null    from "DATASET_WITH_NULL"  WHERE "date" is null;
    select "Missing Value Weight" into missing_value from :var_data where "Variable" = 'date_DoM';
    if ( :count_null  !=  :missing_value  ) then
	   signal ERROR set MESSAGE_TEXT = 'Wrong Missing Value for date' ;
	end if;  

END;
