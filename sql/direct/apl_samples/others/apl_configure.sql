-- ================================================================
-- APL_AREA, CONFIGURE
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).


connect USER_APL password Password1;

drop table CONFIGURATION;
create table CONFIGURATION like CONFIGURATION_T;
drop table CONFIGURATION_OUTPUT;
create table CONFIGURATION_OUTPUT like CONFIGURATION_OUTPUT_T;

-- Set all APL.SERVICES loggers severity to DEBUG.
insert into CONFIGURATION values ('TRACES.APL.SERVICES', 'DEBUG');
DO BEGIN     
    config             = select * from CONFIGURATION;    
    
    _SYS_AFL.APL_AREA_CONFIGURE_PROC(:config, out_config);

    -- store result into table
    insert into  "USER_APL"."CONFIGURATION_OUTPUT"  select * from :out_config;

    -- show result
    select * from CONFIGURATION_OUTPUT;
END;
