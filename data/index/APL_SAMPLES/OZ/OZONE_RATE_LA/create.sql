CREATE COLUMN TABLE "APL_SAMPLES"."OZONE_RATE_LA" ("Date" DATE CS_DAYDATE, "OzoneRateLA" DECIMAL(6,2) CS_FIXED) UNLOAD PRIORITY 5  AUTO MERGE ;
COMMENT ON COLUMN "APL_SAMPLES"."OZONE_RATE_LA"."Date" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."OZONE_RATE_LA"."OzoneRateLA" is ' '