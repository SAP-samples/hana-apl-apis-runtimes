-- @required(hanaMinimumVersion,4.00.000)
-- ================================================================
-- APL_AREA, CREATE_MODEL, using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin_ex.sql).

connect USER_APL password Password1;
SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#69');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('ModelFormat', 'bin');

drop table CREATE_CONFIG;
create table CREATE_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
insert into CREATE_CONFIG values ('APL/ModelType', 'regression/classification',null);

drop table MODEL_BIN;
create table MODEL_BIN like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

drop table VARIABLE_DESC_OUT;
create table VARIABLE_DESC_OUT like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";


drop view ADULT01_ANY;
create view ADULT01_ANY as ( select 
	to_integer("age") as "age",
	"workclass",
	to_integer("fnlwgt") as "fnlwgt",
	"education",
	to_integer("education-num") as "education-num",
	"marital-status",
	"occupation",
	"relationship",
	"race",
	"sex",
	to_integer("capital-gain") as "capital-gain",
	to_integer("capital-loss") as "capital-loss",
	to_integer("hours-per-week") as "hours-per-week",
	"native-country",
	to_integer("class") as "class"
from "APL_SAMPLES"."ADULT01" );


-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
	declare out_model "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";
	declare out_var_desc "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
    header   = select * from FUNC_HEADER;             
    config   = select * from CREATE_CONFIG;  
    dataset  = SELECT * FROM "USER_APL"."ADULT01_ANY";
	
    "_SYS_AFL"."APL_CREATE_MODEL"(:header, :config,:dataset,out_model,out_var_desc);

    -- store result into table
    insert into  "USER_APL"."MODEL_BIN"          select * from :out_model;
    insert into  "USER_APL"."VARIABLE_DESC_OUT"  select * from :out_var_desc;

	-- show result
	select * from "USER_APL"."MODEL_BIN";
	select * from "USER_APL"."VARIABLE_DESC_OUT";
END;
