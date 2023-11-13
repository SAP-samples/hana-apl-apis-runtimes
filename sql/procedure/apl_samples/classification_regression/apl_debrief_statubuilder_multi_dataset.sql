-- ================================================================
-- APL_AREA, CREATE_MODEL_AND_TRAIN, using a binary format for the model
-- This script creates a model, guesses its description and trains it
--
-- Assumption 1: the users & privileges have been created & granted (see apl_admin_ex.sql).
-- Assumption 2: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
-- Assumption 3: Apply result in "ADULT01_APPLY" table.
--  @depend(apl_apply_model_ex.sql)

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';
-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table STAT_CONFIG;
create table STAT_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into STAT_CONFIG values ('APL/VariableEstimatorOf', 'rr_class;class',null);
insert into STAT_CONFIG values ('APL/CurveType','detected',null);


drop table STAT_VARIABLE_DESC;
create table STAT_VARIABLE_DESC like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";

drop table INDICATORS_DATASET;
create table INDICATORS_DATASET like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.INDICATORS_DATASET";

drop table PROFITCURVES;
create table PROFITCURVES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.PROFITCURVE";


-- define var description 
insert into STAT_VARIABLE_DESC values(0,'KxIndex','integer','continuous',1,0,'','','',null);
insert into STAT_VARIABLE_DESC values(1,'class','integer','nominal',0,0,'','','',null);
insert into STAT_VARIABLE_DESC values(2,'rr_class','number','continuous',0,0,'','','',null);

drop table STAT_VARIABLE_ROLES;
create table STAT_VARIABLE_ROLES like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
insert into STAT_VARIABLE_ROLES values ('class', 'target',null,null,null);

drop view  "TEST";
create view  "TEST" as ( select "KxIndex" as "id" , "class", "rr_class" from "USER_APL"."ADULT01_APPLY"     LIMIT 1000 OFFSET 30000);

drop view "ESTIMATION";
create view "ESTIMATION" as (select "KxIndex" as "id" , "class", "rr_class" from "USER_APL"."ADULT01_APPLY" LIMIT 40000 OFFSET 10000);

drop view  "VALIDATION";
create view "VALIDATION" as (select "KxIndex" as "id" , "class", "rr_class" from "USER_APL"."ADULT01_APPLY" LIMIT 10000);


DO BEGIN     
   header      = select * from FUNC_HEADER;
   config      = select * from STAT_CONFIG; 
   var_desc    = select * from STAT_VARIABLE_DESC;              
   var_role    = select * from STAT_VARIABLE_ROLES;  

	"SAP_PA_APL"."sap.pa.apl.base::DEBRIEF_APPLY_RESULT"(:header, :config, :var_desc, :var_role, 'USER_APL', 'ESTIMATION',   'USER_APL','VALIDATION',   'USER_APL','TEST',out_log, out_summ, out_indic, out_curve);
    
    -- store result into table
    insert into  "USER_APL"."OPERATION_LOG"       select * from :out_log;
    insert into  "USER_APL"."SUMMARY"             select * from :out_summ;
    insert into  "USER_APL"."INDICATORS_DATASET"  select * from :out_indic;
    insert into  "USER_APL"."PROFITCURVES"         select * from :out_curve;

	-- show result
    select * from INDICATORS_DATASET;
    select * from PROFITCURVES; 
END;
