-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

DROP TABLE USER_APL.ADULT_WITH_TAB_DATA;
CREATE TABLE USER_APL.ADULT_WITH_TAB_DATA AS (SELECT *  FROM APL_SAMPLES.CENSUS) WITH DATA;
ALTER TABLE USER_APL.ADULT_WITH_TAB_DATA ALTER ( "sex" NVARCHAR(255));
UPDATE USER_APL.ADULT_WITH_TAB_DATA SET "sex"='F\r'||char(10)||'\nemale_ctrlchar' where "sex"='Female';
UPDATE USER_APL.ADULT_WITH_TAB_DATA SET "sex"='Ma\t'||char(9)||'\tle_ctrlchar' where "sex"='Male';

DO BEGIN
	declare ERROR condition for SQL_ERROR_CODE 10001;
    declare count_1 integer;
    declare count_2 integer;
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare debrief_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";      
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      
    declare out_model "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";      
    declare out_log   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";      
    declare out_sum   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";      
    declare out_indic "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";      
    declare out_debrief_metric "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";      
    declare out_debrief_property "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";      

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '8'));
    :header.insert(('ModelFormat', 'bin'));

    :config.insert(('APL/ModelType', 'regression/classification',null));
    :config.insert(('APL/VariableAutoSelection', 'false',null));

    :var_role.insert(('class', 'target', null, null, null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role,  'USER_APL','ADULT_WITH_TAB_DATA',out_model,out_log,out_sum,out_indic);    
    "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_DEBRIEF"(:header, :out_model, :debrief_config, out_debrief_metric,out_debrief_property, out_sum);

    select count(*) into count_1 from :out_indic where value  like '%_ctrlchar%'     or  cast(detail as NVARCHAR(255)) like '%_ctrlchar%';
    select count(*) into count_2 from :out_indic where value  like '%'||char(9)||'%' or  value like '%'||char(10)||'%' or cast(detail as NVARCHAR(255))  like '%'||char(9)||'%' or  cast(detail as NVARCHAR(255))  like '%'||char(10)||'%';
	if (count_1 != count_2) then
	   signal ERROR set MESSAGE_TEXT = 'Wrong ctrl char encoding detected in INDICATOR' ;
	end if;    

    select count(*) into count_1 from :out_debrief_property where value like '%_ctrlchar%'     or long_value like '%_ctrlchar%';
    select count(*) into count_2 from :out_debrief_property where value like '%'||char(9)||'%' or  value like '%'||char(10)||'%' or long_value  like '%'||char(9)||'%' or long_value  like '%'||char(10)||'%';
	if (count_1 != count_2) then
	   signal ERROR set MESSAGE_TEXT = 'Wrong ctrl char encoding detected in DEBRIEF proporties';
	end if;    
END;
