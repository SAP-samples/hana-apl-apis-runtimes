CREATE COLUMN TABLE "APL_SAMPLES"."CONTACT_EVENTS" ("CALLER" NVARCHAR(10), "CALLEE" NVARCHAR(10), "CLASS" NVARCHAR(5), "DATE" LONGDATE CS_LONGDATE, "DURATION" INTEGER CS_INT) UNLOAD PRIORITY 5  AUTO MERGE ;
COMMENT ON COLUMN "APL_SAMPLES"."CONTACT_EVENTS"."CALLER" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CONTACT_EVENTS"."CALLEE" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CONTACT_EVENTS"."CLASS" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CONTACT_EVENTS"."DATE" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CONTACT_EVENTS"."DURATION" is ' '