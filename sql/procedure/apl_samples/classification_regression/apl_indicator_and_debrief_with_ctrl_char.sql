-- @required(hanaMinimumVersion,2.0.32)
-- ================================================================
connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';


DROP TABLE USER_APL.ADULT_WITH_TAB_DATA;
CREATE TABLE USER_APL.ADULT_WITH_TAB_DATA AS (SELECT *  FROM APL_SAMPLES.CENSUS) WITH DATA;
UPDATE USER_APL.ADULT_WITH_TAB_DATA SET "sex"='F'||char(9)||'male' where "sex"='Female';
UPDATE USER_APL.ADULT_WITH_TAB_DATA SET "sex"='M'||char(10)||'le' where "sex"='Male';
SELECT * FROM USER_APL.ADULT_WITH_TAB_DATA;

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table PROFITCURVES_OUT;
create table PROFITCURVES_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.PROFITCURVE";

drop table DEBRIEF_METRIC;
create table DEBRIEF_METRIC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";

drop table DEBRIEF_PROPERTY;
create table DEBRIEF_PROPERTY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";

DO BEGIN
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
    :config.insert(('APL/VariableAutoSelection', 'true',null));

    :var_role.insert(('class', 'target', null, null, null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role,  'USER_APL','ADULT_WITH_TAB_DATA',out_model,out_log,out_sum,out_indic);    
    "SAP_PA_APL"."sap.pa.apl.base::GET_MODEL_DEBRIEF"(:header, :out_model, :debrief_config, out_debrief_metric,out_debrief_property, out_sum);

    insert into "USER_APL"."INDICATORS"  select *  from :out_indic;
    insert into "USER_APL"."DEBRIEF_METRIC" select * from :out_debrief_metric;
    insert into "USER_APL"."DEBRIEF_PROPERTY" select * from :out_debrief_property;
END;


select * from "SAP_PA_APL"."sap.pa.apl.debrief.internal.entity::SL_PROFIT_CURVE"("USER_APL"."DEBRIEF_PROPERTY","USER_APL"."DEBRIEF_METRIC") where CURVE_TYPE='CATEGORY_SIGNIFICANCE' and LABEL  like '%le}';
select * from "USER_APL"."INDICATORS" where cast(detail as NVARCHAR(255)) like '%le}' or cast(value as NVARCHAR(255)) like '%le}';