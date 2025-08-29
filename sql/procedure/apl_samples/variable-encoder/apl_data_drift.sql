-- ================================================================
-- APL_AREA, COMPARE_DATA
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

connect USER_APL password Password1;

-- --------------------------------------------------------------------------
-- Create the dataset
-- --------------------------------------------------------------------------
drop view DATASET_1;
create view DATASET_1 as    
select * from APL_SAMPLES.AUTO_CLAIMS_FRAUD where gender = 'Male' order by 1;

drop view DATASET_2;
create view DATASET_2 as   
select * from APL_SAMPLES.AUTO_CLAIMS_FRAUD where gender = 'Female' order by 1;

-- --------------------------------------------------------------------------
-- compute drift between DATASET_1 and DATASET_2
-- --------------------------------------------------------------------------
DO BEGIN
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";      
    declare out_log   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";             
    declare out_summary  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";   
    declare out_metric   "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_METRIC_OID";      
    declare out_property "SAP_PA_APL"."sap.pa.apl.base::BASE.T.DEBRIEF_PROPERTY_OID";

    :header.insert(('Oid', 'Stat Mdl'));

    :config.insert(('APL/ModelType', 'variable-encoder',null));

	:var_desc.insert((0,'CLAIM_ID','string','nominal',1,0,null,null,'Unique Id',null));
    :var_desc.insert((1,'DAYS_TO_REPORT','integer','continuous',0,0,null,null,null,null));
    :var_desc.insert((2,'BODILY_INJURY_AMOUNT','integer','continuous',0,0,null,null,null,null));
    :var_desc.insert((3,'PROPERTY_DAMAGE','integer','continuous',0,0,null,null,null,null));
    :var_desc.insert((4,'PREVIOUS_CLAIMS','integer','ordinal',0,0,null,null,'',null));
    :var_desc.insert((5,'PAYMENT_METHOD','string','nominal',0,0,null,null,null,null));
    :var_desc.insert((6,'IS_REAR_END_COLLISION','string','nominal',0,0,null,null,null,null));
    :var_desc.insert((7,'PREM_AMOUNT','string','nominal',0,0,null,null,null,null));
    :var_desc.insert((8,'AGE','integer','continuous',0,0,null,null,null,null));
    :var_desc.insert((9,'GENDER','string','nominal',0,0,null,null,null,null));
    :var_desc.insert((10,'MARITAL_STATUS','string','nominal',0,0,null,null,null,null));
    :var_desc.insert((11,'INCOME_ESTIMATE','number','continuous',0,0,null,null,null,null));
    :var_desc.insert((12,'INCOME_CATEGORY','integer','ordinal',0,0,null,null,null,null));
    :var_desc.insert((13,'POLICY_HOLDER','string','nominal',0,0,null,null,null,null));
    :var_desc.insert((14,'IS_FRAUD','string','nominal',0,0,null,null,'Yes/No flag',null));
	
    :var_role.insert(('CLAIM_ID', 'skip', null, null, null));
    :var_role.insert(('IS_FRAUD', 'target', null, null, null));
   
	"SAP_PA_APL"."sap.pa.apl.base::COMPARE_DATA" (:header, :config, :var_desc, :var_role,'USER_APL','DATASET_1', 'USER_APL','DATASET_2', out_log, out_summary, out_metric, out_property);

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
