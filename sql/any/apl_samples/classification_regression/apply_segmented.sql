-- @required(hanaMinimumVersion,2.0.30)
-- @required(hanaMaximumVersion,2.99.999)
-- ================================================================
-- APL_AREA, PARALLEL APPLY_MODEL, using a binary format for the model
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid trained model (created by APL) in the MODEL_TRAIN_BIN table.
-- Assumption 4: You are using Hana 2.0+ and running APL built with AFL SDK 2.0
--  @depend(apl_createmodel_and_train_any.sql)

-- --------------------------------------------------------------------------
-- Create table type for the dataset
-- --------------------------------------------------------------------------

connect USER_APL password Password1;

-- Input table type: dataset
drop type ADULT01_T_P;
create type ADULT01_T_P as table (
    "seg" VARCHAR(4),
	"age" INTEGER,
	"workclass" NVARCHAR(32),
	"fnlwgt" INTEGER,
	"education" NVARCHAR(32),
	"education-num" INTEGER,
	"marital-status" NVARCHAR(32),
	"occupation" NVARCHAR(32),
	"relationship" NVARCHAR(32),
	"race" NVARCHAR(32),
	"sex" NVARCHAR(16),
	"capital-gain" INTEGER,
	"capital-loss" INTEGER,
	"hours-per-week" INTEGER,
	"native-country" NVARCHAR(32),
	"class" INTEGER
);


-- Ouput table type: dataset
drop type ADULT01_T_OUT;
create type ADULT01_T_OUT as table (
    "KxIndex" INTEGER,
    "class" INTEGER,
    "rr_class" DOUBLE
);


drop type ADULT01_T_OUT_P;
create type ADULT01_T_OUT_P as table (
    "seg"     VARCHAR(4),
    "KxIndex" INTEGER,
    "class" INTEGER,
    "rr_class" DOUBLE
);


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
insert into FUNC_HEADER values ('Oid', '#42');
insert into FUNC_HEADER values ('LogLevel', '8');
insert into FUNC_HEADER values ('CheckOperationConfig', 'true');
insert into FUNC_HEADER values ('ModelFormat', 'bin');


drop table APPLY_CONFIG;
create table APPLY_CONFIG like "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_EXTENDED";
-- TODO: insert training configuration parameters (to be defined)

drop table ADULT01_APPLY;
create table ADULT01_APPLY like ADULT01_T_OUT_P;

-- Add seg column into input table as parallel parametre
drop table APPLY_IN ;
create table APPLY_IN like ADULT01_T_P;
insert into APPLY_IN( "seg","age","workclass","fnlwgt","education","education-num","marital-status","occupation","relationship","race","sex","capital-gain","capital-loss","hours-per-week","native-country","class")  
select  
    'seg1' as "seg", 
	to_integer("age") as "age",
	"workclass",
	to_integer("fnlwgt") as "fnlwgt",
	"education" ,
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
from  "APL_SAMPLES"."ADULT01";

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
call "_SYS_AFL"."APL_APPLY_MODEL__OVERLOAD_4_1"(FUNC_HEADER, MODEL_TRAIN_BIN, APPLY_CONFIG, APPLY_IN, ADULT01_APPLY) with overview WITH HINT(PARALLEL_BY_PARAMETER_VALUES (p4."seg"));


select * from "USER_APL"."ADULT01_APPLY";
