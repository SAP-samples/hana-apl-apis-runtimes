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
create column table EXPORT_PROFITCURVES_SIGNATURE   like PROCEDURE_SIGNATURE_T;

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

drop table PROFITCURVES_OUT;
create table PROFITCURVES_OUT like PROFITCURVE_T;

-- --------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------

drop table EXPORT_CONFIG_1;
create table EXPORT_CONFIG_1 like OPERATION_CONFIG_T;
insert into EXPORT_CONFIG_1 values ('APL/CurveType', 'lift');
insert into EXPORT_CONFIG_1 values ('APL/CurvePointCount', '10');
insert into EXPORT_CONFIG_1 values ('APL/CurveBasedOnFrequency', 'true');
insert into EXPORT_CONFIG_1 values ('APL/CurveUsingWeight', 'false');
insert into EXPORT_CONFIG_1 values ('APL/CurveUsingGroups', 'false');

drop table  EXPORT_CONFIG_2;
create table EXPORT_CONFIG_2 like OPERATION_CONFIG_T;
insert into EXPORT_CONFIG_2 values ('APL/CurveType', 'roc');
insert into EXPORT_CONFIG_2 values ('APL/CurvePointCount', '20');
insert into EXPORT_CONFIG_2 values ('APL/CurveBasedOnFrequency', 'false');
insert into EXPORT_CONFIG_2 values ('APL/CurveUsingWeight', 'true');
insert into EXPORT_CONFIG_2 values ('APL/CurveUsingGroups', 'true');

drop table  EXPORT_CONFIG_3;
create table EXPORT_CONFIG_3 like OPERATION_CONFIG_T;
insert into EXPORT_CONFIG_3 values ('APL/CurveType', 'normalProfit');
insert into EXPORT_CONFIG_3 values ('APL/CurvePointCount', '30');
insert into EXPORT_CONFIG_3 values ('APL/CurveBasedOnFrequency', 'true');
insert into EXPORT_CONFIG_3 values ('APL/CurveUsingWeight', 'true');
insert into EXPORT_CONFIG_3 values ('APL/CurveUsingGroups', 'true');
DO BEGIN     
    header           = select * from FUNC_HEADER;             
    model_in         = select * from MODEL_TRAIN_BIN;
    export_1_config  = select * from EXPORT_CONFIG_1; 
    export_2_config  = select * from EXPORT_CONFIG_2; 
    export_3_config  = select * from EXPORT_CONFIG_3; 

    APLWRAPPER_EXPORT_PROFITCURVES(:header, :model_in, :export_1_config, :export_1);
    APLWRAPPER_EXPORT_PROFITCURVES(:header, :model_in, :export_2_config, :export_2);
    APLWRAPPER_EXPORT_PROFITCURVES(:header, :model_in, :export_3_config, :export_3);

    -- store result into table
    insert into  "USER_APL"."PROFITCURVES_OUT" select * from :export_1;
    insert into  "USER_APL"."PROFITCURVES_OUT" select * from :export_2;
    insert into  "USER_APL"."PROFITCURVES_OUT" select * from :export_3;

	-- show result
    select * from "USER_APL"."PROFITCURVES_OUT";
END;


