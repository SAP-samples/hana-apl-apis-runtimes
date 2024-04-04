 @required(hanaMinimumVersion,2.0.32)
-- ================================================================
connect USER_APL password Password1;
drop table MODEL_TRAIN_BIN;
create table MODEL_TRAIN_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

DO BEGIN
   declare INVALID_INPUT condition for SQL_ERROR_CODE 10001;
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare debrief_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";      
    declare var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";      
    declare var_role "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
    declare count    integer;


    :header.insert(('Oid', '#42'));
    :header.insert(('CheckOperationConfig', 'true'));

    :config.insert(('APL/ModelType', 'regression/classification',null));
	:config.insert(('APL/DebriefFormat', 'application/vnd.sap.aa.debrief.generic.1.0',NULL));
    :config.insert(('APL/DebriefMetadata', 'true',null));
    :config.insert(('APL/DebriefId', '10',null));
    :config.insert(('APL/DebriefVersion', '1.3.0.0',null));

    :var_role.insert(('class', 'target', null, null, null));

    "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role, 'APL_SAMPLES','ADULT01', model,  train_log, train_sum, train_indic);
     
     select count(*) into count from :model where  FORMAT ='application/vnd.sap.aa.debrief.generic.1.0';
     if ( :count = 0 ) then
       signal INVALID_INPUT set MESSAGE_TEXT = 'no debrief';   
     end if;   

     select count(*) into count from :model where  FORMAT ='application/vnd.sap.aa';
     if ( :count = 0 ) then
       signal INVALID_INPUT set MESSAGE_TEXT = 'no model';   
     end if;
    
     insert into  "USER_APL"."MODEL_TRAIN_BIN" select * from :model;

END;

select * from "USER_APL"."MODEL_TRAIN_BIN";
