connect USER_APL password Password1;

-- get Poegress log
select * from "_SYS_AFL"."FUNCTION_PROGRESS_IN_APL_AREA";

-- delete progress log
call "_SYS_AFL"."APL_AREA_PROGRESS_CLEANUP_PROC"('#42',?);