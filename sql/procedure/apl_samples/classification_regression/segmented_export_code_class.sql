-- ================================================================
-- APL_AREA, EXPORT_APPLY_CODE
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
--  @depend(segmented_create_train_class.sql)
connect USER_APL password Password1;
-- Uncomment to modify the cache location to schema APL_CACHE 
-- SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table EXPORT_JSON;
create table EXPORT_JSON like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.RESULT";

DO BEGIN     
    declare header "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
    declare export_config "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";   
    declare model "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";      
    declare out_code_result "SAP_PA_APL"."sap.pa.apl.base::BASE.T.RESULT";      

	model = select * from MODEL_TRAIN_BIN;

    :header.insert(('Oid', '#42'));
    :header.insert(('LogLevel', '2'));
    :header.insert(('CheckOperationConfig', 'true'));
    :header.insert(('MaxTasks', '2'));  -- define nb parallel tasks to use for train

    :export_config.insert(('APL/SegmentColumnName', 'Seg',null)); -- define the column used as the segmentation colum
    :export_config.insert(('APL/CodeType', 'JSON',null));

    call "SAP_PA_APL"."sap.pa.apl.base::EXPORT_APPLY_CODE"(:header, :model, :export_config, :out_code_result);
	
	-- store result into table
 	insert into  EXPORT_JSON select * from :out_code_result;
END;

select * from  EXPORT_JSON  WHERE KEY = 'code';
