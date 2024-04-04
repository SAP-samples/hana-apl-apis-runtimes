-- @required(hanaMinimumVersion,2.0.40)
-- ================================================================
-- APL_AREA, FORECAST
-- Description :
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).
--  @depend(apl_apply_proc.sql)

connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create a view which contains the sorted dataset
-- --------------------------------------------------------------------------

drop view TS_SORTED;
create view TS_SORTED as  select "Date" as "The_Time", "OzoneRateLA"  from APL_SAMPLES.OZONE_RATE_LA order by "Date" ;

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table MODEL_BIN_OUT;
create table MODEL_BIN_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table APPLY_DEBRIEF_METRIC;
create table APPLY_DEBRIEF_METRIC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";

drop table APPLY_DEBRIEF_PROPERTY;
create table APPLY_DEBRIEF_PROPERTY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";

drop table APPLY_OUT;

DO BEGIN
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED"; 
    declare apply_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
     
    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '8'));
    :header.insert(('ModelFormat', 'bin'));
    :header.insert(('CheckOperationConfig', 'true'));

    :config.insert(('APL/ModelType', 'timeseries',null));
    :config.insert(('APL/Horizon', '6',null));
    :config.insert(('APL/TimePointColumnName', 'Date',null));
	:config.insert(('APL/ActivateExplanations', 'true',null));
	:config.insert(('APL/DecomposeInfluencers', 'true',null));
	:config.insert(('APL/LastTrainingTimePoint', '1971-12-28 00:00:00',null)); 
		
	:var_desc.insert((0,'Date','datetime','continuous',1,0,null,null,'Unique Id',null));
    :var_desc.insert((1,'Actual','number','continuous',0,0,null,null,null,null));
	
    :var_role.insert(('Date', 'input', null, null, null));
	:var_role.insert(('Actual', 'target', null, null, null));

    :apply_config.insert(('APL/ApplyLastTimePoint', '1971-12-28 00:00:00',null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role, 'USER_APL','TS_SORTED', model,  train_log, train_sum, train_indic);          

    call "apl_apply_debrief_example"(:header, :model,  :apply_config, 'USER_APL','TS_SORTED', 'USER_APL','APPLY_OUT',out_apply_log,out_apply_sum,out_debrief_metric, out_debrief_property);

    -- store result into table
    insert into  "USER_APL"."MODEL_BIN_OUT"   select * from :model;
    insert into  "USER_APL"."APPLY_DEBRIEF_PROPERTY" select * from :out_debrief_property;
    insert into  "USER_APL"."APPLY_DEBRIEF_METRIC"   select * from :out_debrief_metric;
END;

select * from "USER_APL"."APPLY_OUT";
select * from "USER_APL"."APPLY_DEBRIEF_PROPERTY";
select * from "USER_APL"."APPLY_DEBRIEF_METRIC";
