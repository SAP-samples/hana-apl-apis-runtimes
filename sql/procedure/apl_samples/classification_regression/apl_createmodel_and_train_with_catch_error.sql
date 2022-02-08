-- @required(hanaMinimumVersion,2.0.30)
-- ================================================================
-- APL_AREA, CREATE_MODEL_AND_TRAIN, using a binary format for the model
-- This script creates a model, guesses its description and trains it
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table CREATE_AND_TRAIN_CONFIG;
create table CREATE_AND_TRAIN_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into CREATE_AND_TRAIN_CONFIG values ('APL/ModelType', 'regression/classification',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/VariableAutoSelection', 'true',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/VariableSelectionBestIteration', 'true',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/VariableSelectionMaxNbOfFinalVariables', '5',null);
insert into CREATE_AND_TRAIN_CONFIG values ('APL/VariableSelectionMinNbOfFinalVariables', '1',null);


drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- let this table empty to use guess variables

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
-- variable roles are optional, hence the empty table

DROP VIEW DATASET;
-- Create a dataset with only one value for target in order to generate a error in APL
-- The column 'class' can't be used as a target because it doesn't exclusively contain two distinct values.
-- Please select a binary column that contains exactly two distinct values.]
-- CREATE VIEW DATASET AS ( SELECT "age", "workclass",  "class" as "a_column_with_an_exceptionnally_long_name_that_triggers_some_truncation_in_case_of_error" FROM "APL_SAMPLES"."ADULT01" ORDER BY "class" LIMIT 1000 );
CREATE VIEW DATASET AS ( SELECT "age", "workclass",  "class" as "a_column_with_an_exceptionnally_long_name_that_triggers_some_truncation_in_case_of_error" FROM "APL_SAMPLES"."ADULT01" ORDER BY "class" );


DO BEGIN
    header   = select * from FUNC_HEADER;             
    config   = select * from CREATE_AND_TRAIN_CONFIG;            
    var_desc = select * from VARIABLE_DESC;              
    var_role = select * from VARIABLE_ROLES;  
   
    -- Active function progress ( ProgressLog=async and Cancelable=true )
    :header.insert(('ProgressLog','async'));
    :header.insert(('Cancelable','true'));
   
    BEGIN
	    -- Catch Error throw by apl and get error message from function progress table 
	    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN
			DECLARE error_message NCLOB;
			DECLARE function_call NCLOB;
		    DECLARE oid           NVARCHAR(255);
		    select  VALUE INTO  oid DEFAULT ('') from :header WHERE KEY = 'Oid';  
			-- error message may be splitted in several chunks if too long. This will collect and properly merge all chunks if any
			SELECT '['||STRING_AGG("PROGRESS_MESSAGE" ORDER BY "PROGRESS_TIMESTAMP" DESC, "PROGRESS_LEVEL")||']',"FUNCTION_NAME" INTO error_message ,function_call  DEFAULT '','' FROM "_SYS_AFL"."FUNCTION_PROGRESS_IN_APL_AREA" WHERE "PROGRESS_LEVEL" like 'error%' AND "EXECUTION_ID" = :oid GROUP BY "FUNCTION_NAME";
		    
		   -- Clean Progress log table  
		    CALL "_SYS_AFL".APL_AREA_PROGRESS_CLEANUP_PROC(:oid, ?);
		   
		    IF (:error_message <> '') THEN
		        -- Throw new exception with computed error message 
		        SIGNAL SQL_ERROR_CODE 13000 SET MESSAGE_TEXT =  'Error in function:' ||:function_call ||' with message:'|| :error_message;
		    ELSE
		       -- rethrow orignal exception because no error message was found in function progress
		       RESIGNAL;
		    END IF;	
		END;
	    
		CALL "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL_AND_TRAIN"(:header, :config, :var_desc,:var_role, 'USER_APL','DATASET', :model,  :train_log, :train_sum, :train_indic);    
    END;
END;
