-- ================================================================
-- APL_AREA, EXPORT_PROFITCURVES
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

drop table EXPORT_PROFITCURVES_SIGNATURE;
create table EXPORT_PROFITCURVES_SIGNATURE   like PROCEDURE_SIGNATURE_T;

insert into EXPORT_PROFITCURVES_SIGNATURE values (1, 'USER_APL','FUNCTION_HEADER_T', 'IN');
insert into EXPORT_PROFITCURVES_SIGNATURE values (2, 'USER_APL','MODEL_BIN_OID_T', 'IN');
insert into EXPORT_PROFITCURVES_SIGNATURE values (3, 'USER_APL','OPERATION_CONFIG_T', 'IN');
insert into EXPORT_PROFITCURVES_SIGNATURE values (4, 'USER_APL','PROFITCURVE_T', 'OUT');

call SYS.AFLLANG_WRAPPER_PROCEDURE_DROP('USER_APL','APLWRAPPER_EXPORT_PROFITCURVES');
call SYS.AFLLANG_WRAPPER_PROCEDURE_CREATE('APL_AREA','EXPORT_PROFITCURVES','USER_APL', 'APLWRAPPER_EXPORT_PROFITCURVES', EXPORT_PROFITCURVES_SIGNATURE);


-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
drop table FUNC_HEADER;
create table FUNC_HEADER like FUNCTION_HEADER_T;
insert into FUNC_HEADER values ('Oid', '#42');

drop table EXPORT_CONFIG;
create table EXPORT_CONFIG like OPERATION_CONFIG_T;
insert into EXPORT_CONFIG values ('APL/CurveType', 'proba');
insert into EXPORT_CONFIG values ('APL/CurvePointCount', '10');
insert into EXPORT_CONFIG values ('APL/CurveBasedOnFrequency', 'true');
insert into EXPORT_CONFIG values ('APL/CurveUsingWeight', 'true');
insert into EXPORT_CONFIG values ('APL/CurveUsingGroups', 'true');

drop table PROFITCURVES_OUT;
create table PROFITCURVES_OUT like PROFITCURVE_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
DO BEGIN     
    header           = select * from FUNC_HEADER;             
    model_in         = select * from MODEL_TRAIN_BIN;
    export_config  = select * from EXPORT_CONFIG; 

    APLWRAPPER_EXPORT_PROFITCURVES(:header, :model_in, :export_config, out_export);

    -- store result into table
    insert into  "USER_APL"."PROFITCURVES_OUT" select * from :out_export;

	-- show result
    select * from "USER_APL"."PROFITCURVES_OUT";
END;
