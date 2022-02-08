-- ================================================================
-- APL_AREA, SCORING_EQUATION, overloaded version with 5+5 parameters, using a binary format for the model
-- This script generates the scoring equation in SQL from an existing dataset
-- This script also generates the profit curves associated to the underlyin model.
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

drop table SCORING_EQUATION_CONFIG;
create table SCORING_EQUATION_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into SCORING_EQUATION_CONFIG values ('APL/CodeType', 'HANA',null);
insert into SCORING_EQUATION_CONFIG values ('APL/CodeTarget', 'class',null);
insert into SCORING_EQUATION_CONFIG values ('APL/CodeKey', '"id"',null);
insert into SCORING_EQUATION_CONFIG values ('APL/CodeSpace', 'APL_SAMPLES.CENSUS',null);
insert into SCORING_EQUATION_CONFIG values ('APL/ApplyExtraMode', 'No Extra',null);

drop table VARIABLE_DESC;
create table VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- let this table empty to make the engine guess the variable descriptions

drop table VARIABLE_ROLES;
create table VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
-- variable roles are optional, hence the empty table

drop table OPERATION_LOG;
create table OPERATION_LOG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_LOG";

drop table SUMMARY;
create table SUMMARY like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.SUMMARY";

drop table INDICATORS;
create table INDICATORS like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS";

drop table SCORING_EQUATION;
create table SCORING_EQUATION like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.RESULT";

drop table PROFITCURVES_OUT;
create table PROFITCURVES_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.PROFITCURVE";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header   = select * from FUNC_HEADER;       
    config   = select * from SCORING_EQUATION_CONFIG;
    var_desc = select * from VARIABLE_DESC;              
    var_role = select * from VARIABLE_ROLES;  

    "SAP_PA_APL"."sap.pa.apl.base::SCORING_EQUATION"(:header, :config, :var_desc, :var_role,'APL_SAMPLES','CENSUS',  out_log, out_sum, out_indic, out_equation, out_curves);
    
    -- store result into table
    insert into  "USER_APL"."OPERATION_LOG"    select * from :out_log;
    insert into  "USER_APL"."SUMMARY"          select * from :out_sum;
    insert into  "USER_APL"."INDICATORS"       select * from :out_indic;
    insert into  "USER_APL"."SCORING_EQUATION" select * from :out_equation;
    insert into  "USER_APL"."PROFITCURVES_OUT" select * from :out_curves;

	-- show result
	select * from "USER_APL"."OPERATION_LOG";
	select * from "USER_APL"."SUMMARY";
	select * from "USER_APL"."INDICATORS";
	select * from "USER_APL"."SCORING_EQUATION";
	select * from "USER_APL"."PROFITCURVES_OUT";
END;
