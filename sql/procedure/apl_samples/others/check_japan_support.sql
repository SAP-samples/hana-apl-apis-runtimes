-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

drop table "DATASET";
create table "DATASET" as (  SELECT "age" AS "年", CAST("workclass" as NVARCHAR(256)) AS "ワーククラス", "fnlwgt", "capital-gain","capital-loss","hours-per-week","class" AS "クラス" FROM "APL_SAMPLES"."ADULT01");

drop table "DATASET_WITH_JAPAN";
create table "DATASET_WITH_JAPAN" as ( select *  from DATASET);

UPDATE "DATASET_WITH_JAPAN" SET "ワーククラス" = '働いたことがない'  WHERE  "ワーククラス" = 'Never-worked';
UPDATE "DATASET_WITH_JAPAN" SET "ワーククラス" = '地方自治体' WHERE  "ワーククラス" = 'Local-gov';
UPDATE "DATASET_WITH_JAPAN" SET "ワーククラス" = '連邦政府' WHERE  "ワーククラス" = 'Federal-gov';
UPDATE "DATASET_WITH_JAPAN" SET "ワーククラス" = '自営業ではない株式会社' WHERE "ワーククラス" = 'Self-emp-not-inc';
UPDATE "DATASET_WITH_JAPAN" SET "ワーククラス" = '支払いなしで' WHERE  "ワーククラス" = 'Without-pay';
UPDATE "DATASET_WITH_JAPAN" SET "ワーククラス" = 'プライベート' WHERE  "ワーククラス" = 'Private';
UPDATE "DATASET_WITH_JAPAN" SET "ワーククラス" = '株式会社セルフエンプ' WHERE  "ワーククラス" = 'Self-emp-inc';
UPDATE "DATASET_WITH_JAPAN" SET "ワーククラス" = '州政府' WHERE  "ワーククラス" = 'State-gov';

drop view "DATASET_VIEW";
create view "DATASET_VIEW" as ( select *  from DATASET_WITH_JAPAN order by  "年", "ワーククラス", "fnlwgt", "capital-gain","capital-loss","hours-per-week","クラス" );

DO BEGIN
    declare ERROR condition for SQL_ERROR_CODE 10001;
    declare nb integer;
    declare cat_list NVARCHAR(2024);
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
    :header.insert(('CheckOperationConfig', 'true'));

    :config.insert(('APL/ModelType', 'regression/classification',null));

    :var_desc.insert((0, '年', 'integer', 'ordinal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((1, 'ワーククラス', 'string', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((2, 'fnlwgt', 'number', 'continuous', 0, 1, 'xxx', NULL, NULL, ''));
    :var_desc.insert((3, 'capital-gain', 'number', 'continuous', 0, 0, 'xxx',NULL, NULL, ''));
    :var_desc.insert((4, 'capital-loss', 'number', 'continuous', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((5, 'hours-per-week', 'number', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));
    :var_desc.insert((6, 'クラス', 'integer', 'nominal', 0, 0, 'xxx', NULL, NULL, ''));

    :var_role.insert(('クラス', 'target', null, null, null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN_DEBRIEF"(:header, :config, :var_desc,:var_role, 'USER_APL','DATASET_WITH_JAPAN',out_model,out_log,out_sum,out_debrief_metric,out_debrief_property);

    -- Dump Statistics Report
    variables = select  * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_Variables"(:out_debrief_property, :out_debrief_metric);
    category = select * from "SAP_PA_APL"."sap.pa.apl.debrief.report::Statistics_CategoryFrequencies"(:out_debrief_property, :out_debrief_metric);
    
    select count(*) INTO nb from :variables where "Variable" = '年';
    if ( :nb = 0  ) then
	   signal ERROR set MESSAGE_TEXT = 'Missing Variable 年';
	end if;    

	select count(*) INTO nb from :variables where "Variable" = 'クラス';
    if ( :nb = 0  ) then
	   signal ERROR set MESSAGE_TEXT = 'Missing Variable クラス';
	end if; 

    select count(*) INTO nb from :variables where "Variable" = 'ワーククラス';
    if ( :nb = 0  ) then
	   signal ERROR set MESSAGE_TEXT = 'Missing Variable ワーククラス';
	end if; 

    category_of =  SELECT *   from :category where "Variable" = 'ワーククラス' AND "Partition" =  'Estimation'  AND TO_VARCHAR("Category") IN  ('プライベート', '地方自治体', '州政府', '株式会社セルフエンプ', '自営業ではない株式会社', '連邦政府');
   
    select STRING_AGG(TO_VARCHAR("Category"), ''', ''') INTO cat_list from :category_of  WHERE TO_VARCHAR("Category") NOT IN ('KxOther', '?', 'プライベート', '地方自治体', '州政府', '株式会社セルフエンプ', '自営業ではない株式会社', '連邦政府'); 
    if  ( :cat_list  is NOT NULL )  then
        signal ERROR set MESSAGE_TEXT = 'Non expected values for Variable ワーククラス :(''' || :cat_list || ''')';
	end if; 
END;
