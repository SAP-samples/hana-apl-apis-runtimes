-- ================================================================
-- APL_AREA, PUBLISH_MODEL
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).
-- Assumption 3: There's a valid and trained model (created by APL) in the MODEL_TRAIN_BIN table.
--               For instance, you have used apl_createmodel_and_train.sql before
--  @depend(apl_createmodel_and_train.sql)
connect USER_APL password Password1;

-- --------------------------------------------------------------------------
-- Create AFL wrappers for the APL function
-- --------------------------------------------------------------------------

-- Generate APLWRAPPER_PUBLISH_MODEL
drop table CALL_SIGNATURE;
create column table CALL_SIGNATURE  like PROCEDURE_SIGNATURE_T;
insert into CALL_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into CALL_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into CALL_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into CALL_SIGNATURE values (4, 'USER_APL','ADMIN_T', 'IN');
insert into CALL_SIGNATURE values (5, 'USER_APL','ADMIN_T', 'OUT');
insert into CALL_SIGNATURE values (6, 'USER_APL','MODEL_NATIVE_T', 'OUT');
insert into CALL_SIGNATURE values (7, 'USER_APL','SUMMARY_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_PUBLISH_MODEL');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','PUBLISH_MODEL','USER_APL', 'APLWRAPPER_PUBLISH_MODEL', CALL_SIGNATURE);

-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');

drop table PUBLISH_CONFIG;
create table PUBLISH_CONFIG like OPERATION_CONFIG_T;
insert into PUBLISH_CONFIG values ('APL/ModelName', 'Train Model');
insert into PUBLISH_CONFIG values ('APL/ModelComment', 'Published from APL');
insert into PUBLISH_CONFIG values ('APL/ModelSpaceName', '"MODELS"');

-- Warning: These drop/create statements are going to remove an existing and working version of the KXADMIN table
-- In a regular use case (not this sample), the KXADMIN table already exists and it's managed by the InfiniteInsight modeler tool.
drop table USER_APL.KXADMIN;
create table USER_APL.KXADMIN like ADMIN_T;

drop table USER_APL.MODELS;
create table USER_APL.MODELS like MODEL_NATIVE_T;

drop table SUMMARY;
create table SUMMARY like SUMMARY_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header           = select * from FUNC_HEADER;             
    model_in         = select * from MODEL_TRAIN_BIN;
    config           = select * from PUBLISH_CONFIG;  
    kxadmin          = select * from USER_APL.KXADMIN;  
    
    APLWRAPPER_PUBLISH_MODEL(:header, :model_in, :config, :kxadmin, out_kxadmin, out_models, out_summ);

    -- store result into table
    insert into  "USER_APL"."KXADMIN"           select * from :out_kxadmin;
    insert into  "USER_APL"."MODELS"            select * from :out_models;
    insert into  "USER_APL"."SUMMARY"           select * from :out_summ;

	-- show result
    select * from "USER_APL"."KXADMIN";
    select * from "USER_APL"."MODELS" ;
    select * from "USER_APL"."SUMMARY";
END;
