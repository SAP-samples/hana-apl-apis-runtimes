-- ================================================================
-- APL_AREA, PING
--
-- Assumption 1: The users & privileges have been created & granted (see apl_admin.sql).
-- Assumption 2: The APL table types have been created (see apl_create_table_types.sql).


connect USER_APL password Password1;

drop table PING_OUTPUT;
create table PING_OUTPUT like PING_OUTPUT_T;
DO BEGIN     
    _SYS_AFL.APL_AREA_PING_PROC(ping);

    -- store result into table
    insert into  "USER_APL"."PING_OUTPUT"  select * from :ping;

    -- show result
    select * from PING_OUTPUT;
END;
