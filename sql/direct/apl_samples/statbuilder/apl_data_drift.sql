-- ================================================================
-- APL_AREA, COMPARE_DATA
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: the APL table types have been created (see apl_create_table_types.sql).

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
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------
drop table CALL_SIGNATURE;
create table CALL_SIGNATURE like PROCEDURE_SIGNATURE_T;

-- Generate APLWRAPPER_COMPARE_DATA
delete from CALL_SIGNATURE;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T',  'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','VARIABLE_DESC_T',    'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','VARIABLE_ROLES_T',   'IN');
insert into CALL_SIGNATURE values (5, 'APL_SAMPLES','AUTO_CLAIMS_FRAUD',          'IN');
insert into CALL_SIGNATURE values (6, 'APL_SAMPLES','AUTO_CLAIMS_FRAUD',          'IN');
insert into CALL_SIGNATURE values (7, 'USER_APL','OPERATION_LOG_T',    'OUT');
insert into CALL_SIGNATURE values (8, 'USER_APL','SUMMARY_T',          'OUT');
insert into CALL_SIGNATURE values (9, 'USER_APL','DEBRIEF_METRIC_OID_T', 'OUT');
insert into CALL_SIGNATURE values (10, 'USER_APL','DEBRIEF_PROPERTY_OID_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_COMPARE_DATA');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','COMPARE_DATA','USER_APL', 'APLWRAPPER_COMPARE_DATA', CALL_SIGNATURE);


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
    
    dataset_ref        = select * from USER_APL.DATASET_1; 
    dataset_new        = select * from USER_APL.DATASET_2; 

    :header.insert(('Oid', 'Stat Mdl'));


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
   
	"APLWRAPPER_COMPARE_DATA" (:header, :config, :var_desc, :var_role,:dataset_ref, :dataset_new, out_log, out_summary, out_metric, out_property);

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
