-- @required(hanaMinimumVersion,2.0.40)
-- ================================================================
-- APL_AREA, IMPORT_MODEL, using a model from Predictive Analytics
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: There is a valid and trained Predictive Analytics's model named 'Train Model' in table "KXADMIN"
--				 For instance, you have used apl_publish_ex.sql before
-- @depend(apl_publish_ex.sql)

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------

drop table APPLY_OUT;

DO BEGIN     
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare apply_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare in_kxadmin "SAP_PA_APL"."sap.pa.apl.base::BASE.T.ADMIN";
    insert into :in_kxadmin select * from KXADMIN;

	-- import a Predictive Analytics's model
	call "SAP_PA_APL"."sap.pa.apl.base::IMPORT_MODEL"(:header, :in_kxadmin, 'Train Model', 1, out_import_model);

	-- use it for an apply
	call "SAP_PA_APL"."sap.pa.apl.base::GET_TABLE_TYPE_FOR_APPLY"(:header, :out_import_model, :apply_config, 'APL_SAMPLES', 'CENSUS', out_schema , out_log);
	call "SAP_PA_APL"."sap.pa.apl.base::CREATE_TABLE_FROM_TABLE_TYPE"('USER_APL', 'APPLY_OUT', :out_schema);
	call "SAP_PA_APL"."sap.pa.apl.base::APPLY_MODEL"(:header, :out_import_model, :apply_config, 'APL_SAMPLES', 'CENSUS', 'USER_APL', 'APPLY_OUT', applyout_log, applyout_summary);				
END;

SELECT * FROM "USER_APL"."APPLY_OUT";




