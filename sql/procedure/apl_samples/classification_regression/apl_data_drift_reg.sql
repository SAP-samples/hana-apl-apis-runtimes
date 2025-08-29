-- ================================================================
-- APL_AREA, PROFILE_DATA
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

connect USER_APL password Password1;

-- --------------------------------------------------------------------------
-- Create the dataset
-- --------------------------------------------------------------------------
drop view DATASET_1;
create view DATASET_1 as    
select * from APL_SAMPLES.CENSUS where "sex" = 'Male' order by "id";

drop view DATASET_2;
create view DATASET_2 as   
select * from APL_SAMPLES.CENSUS where "sex" = 'Female' order by "id";

-- --------------------------------------------------------------------------
-- compute drift between DATASET_1 and DATASET_2
-- --------------------------------------------------------------------------
DO BEGIN
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      
    declare out_model_1 "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID"; 
    declare out_model_2 "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID"; 
    declare out_log   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";             
    declare out_summary  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";   
    declare out_metric   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";      
    declare out_property "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";
    declare out_indicators "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";          

    :header.insert(('Oid', 'Regression Mdl'));

    :config.insert(('APL/ModelType', 'regression/classification',null));
    
    :var_role.insert(('id', 'skip', null, null, null));
    :var_role.insert(('age', 'target', null, null, null));

	:var_desc.insert((0, 'id', 'integer', 'continuous', 1, 0, null, null, 'id variable description',null));
	:var_desc.insert((1, 'age', 'integer', 'continuous', 0, 0, null, null, 'age variable description',null));
	:var_desc.insert((2, 'workclass', 'string', 'nominal', 0, 0, null, null, 'workclass variable description',null));
	:var_desc.insert((3, 'fnlwgt', 'integer', 'continuous', 0, 0, null, null, 'fnlwgt variable description',null));
	:var_desc.insert((4, 'education', 'string', 'nominal', 0, 0, null, null, 'education variable description',null));
	:var_desc.insert((5, 'education-num', 'integer', 'continuous', 0, 0, null, null, 'education-num variable description',null));
	:var_desc.insert((6, 'marital-status', 'string', 'nominal', 0, 0, null, null, 'marital-status variable description',null));
	:var_desc.insert((7, 'occupation', 'string', 'nominal', 0, 0, null, null, 'occupation variable description',null));
	:var_desc.insert((8, 'relationship', 'string', 'nominal', 0, 0, null, null, 'relationship variable description',null));
	:var_desc.insert((9, 'race', 'string', 'nominal', 0, 0, null, null, 'race variable description',null));
	:var_desc.insert((10, 'sex', 'string', 'nominal', 0, 0, null, null, 'sex variable description',null));
	:var_desc.insert((11, 'capital-gain', 'integer', 'continuous', 0, 0, null,null, 'capital-gain variable description',null));
	:var_desc.insert((12, 'capital-loss', 'integer', 'continuous', 0, 0, null, null, 'capital-loss variable description',null));
	:var_desc.insert((13, 'hours-per-week', 'integer', 'continuous', 0, 0, null, null, 'hours-per-week variable description',null));
	:var_desc.insert((14, 'native-country', 'string', 'nominal', 0, 0, null, null, 'native-country variable description',null));
	:var_desc.insert((15, 'class', 'integer', 'nominal', 0, 0, null, null, 'class variable description',null));


    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc, :var_role, 'USER_APL','DATASET_1', out_model_1, out_log, out_summary, out_indicators);

	"SAP_PA_APL"."sap.pa.apl.base::TEST_MODEL_DEBRIEF" (:header, :out_model_1, :config, 'USER_APL','DATASET_2',out_model_2, out_log, out_summary, out_metric, out_property);

    select * from SAP_PA_APL."sap.pa.apl.debrief.report::Deviation_ByVariable"(:out_property,:out_metric);
    select * from SAP_PA_APL."sap.pa.apl.debrief.report::Deviation_ByVariable"(:out_property,:out_metric, Deviation_Threshold => 0.2);
    select * from SAP_PA_APL."sap.pa.apl.debrief.report::Deviation_ByCategory"(:out_property,:out_metric);
    select * from SAP_PA_APL."sap.pa.apl.debrief.report::Deviation_ByCategory"(:out_property,:out_metric, Deviation_Threshold => 0.2);
    select * from SAP_PA_APL."sap.pa.apl.debrief.report::Deviation_TargetBasedByCategory"(:out_property,:out_metric);
    select * from SAP_PA_APL."sap.pa.apl.debrief.report::Deviation_TargetBasedByCategory"(:out_property,:out_metric, Deviation_Threshold => 0.2);    
    select * from SAP_PA_APL."sap.pa.apl.debrief.report::Deviation_CategoryFrequencies"(:out_property,:out_metric); 
    select * from SAP_PA_APL."sap.pa.apl.debrief.report::Deviation_ByGroup"(:out_property,:out_metric);
    select * from SAP_PA_APL."sap.pa.apl.debrief.report::Deviation_ByGroup"(:out_property,:out_metric, Deviation_Threshold => 0.2);
    select * from SAP_PA_APL."sap.pa.apl.debrief.report::Deviation_TargetBasedByGroup"(:out_property,:out_metric);
    select * from SAP_PA_APL."sap.pa.apl.debrief.report::Deviation_TargetBasedByGroup"(:out_property,:out_metric, Deviation_Threshold => 0.2);
    select * from SAP_PA_APL."sap.pa.apl.debrief.report::Deviation_GroupFrequencies"(:out_property,:out_metric); 
END;
