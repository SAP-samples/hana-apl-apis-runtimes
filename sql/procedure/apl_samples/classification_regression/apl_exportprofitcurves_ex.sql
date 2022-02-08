-- ================================================================
-- APL_AREA, EXPORT_PROFITCURVES, using a binary format for the model
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).

-- Assumption 3: There's a valid and trained model (created by APL) in the MODEL_TRAIN_BIN table.
--               For instance, you have used apl_createmodel_and_train_ex.sql before
--  @depend(apl_createmodel_and_train_ex.sql)

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table USER_APL.FUNC_HEADER;
create table USER_APL.FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into USER_APL.FUNC_HEADER values ('Oid', '#69');

drop table USER_APL.EXPORTCURVE_CONFIG;
create table USER_APL.EXPORTCURVE_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into USER_APL.EXPORTCURVE_CONFIG values ('APL/ModelName', 'Train Model',null);
insert into USER_APL.EXPORTCURVE_CONFIG values ('APL/ModelComment', 'Published from APL',null);
insert into USER_APL.EXPORTCURVE_CONFIG values ('APL/ModelSpaceName', '"MODELS"',null);

DO BEGIN     
    header   = select * from FUNC_HEADER;       
    modle_in = select * from MODEL_TRAIN_BIN;   
    config   = select * from EXPORTCURVE_CONFIG;          

   "SAP_PA_APL"."sap.pa.apl.base::EXPORT_PROFITCURVES"(:header, :modle_in, :config, out_curves);
    
	-- show result
    select * from :out_curves;
END;
