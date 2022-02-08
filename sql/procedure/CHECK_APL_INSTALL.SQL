-- ================================================================
-- @configSQL
-- The purpose of this script is to validate the APL installation by:
-- checking that the APL functions are there
-- checking that the APL functions can be called by executing the PING procedure
-- 
-- Assumption: The scripserver is already enabled
--
-- Output: returns 1 when APL has been correctly installed
--         script is failing when APL hasn't been correctly installed

-- !! to change SYSTEM password  (%PASSWORD%) with the correct password 
connect SYSTEM password %PASSWORD%;

-- create a temp user in order to check APL is correctly installed
drop user TMP_USER cascade;
create user TMP_USER password Password1;
alter user TMP_USER disable password lifetime;

call _SYS_REPO.GRANT_ACTIVATED_ROLE ('sap.pa.apl.base.roles::APL_EXECUTE','TMP_USER');

connect TMP_USER password Password1;

create type CHECK_TABLE_T as table (
       "APL Status" varchar(128)
);

create procedure "CHECK_APL_DEPLOYMENT" (out RESULT CHECK_TABLE_T)
language SQLSCRIPT as
begin
       declare IS_APL_AREA_OK integer;
       declare IS_APL_PING_OK integer;
       declare CHECK_TABLE CHECK_TABLE_T;

       select count(*) into IS_APL_AREA_OK from "SYS"."AFL_AREAS" where AREA_NAME='APL_AREA';       

       call "SAP_PA_APL"."sap.pa.apl.base::PING"(:APL_PING_RESULT);       
       select count(*) into IS_APL_PING_OK from :APL_PING_RESULT;

       if :IS_APL_AREA_OK > 0 and :IS_APL_PING_OK > 0 then
		   CHECK_TABLE = SELECT 'APL is installed' AS "APL Status" from DUMMY;           
       else
		   CHECK_TABLE = SELECT '0' AS "APL Status" from DUMMY;           
       end if;
       RESULT = select * from :CHECK_TABLE;
end;


call CHECK_APL_DEPLOYMENT(?);

connect SYSTEM password %PASSWORD%;

-- drop temp user and procedure 
drop user TMP_USER cascade;
