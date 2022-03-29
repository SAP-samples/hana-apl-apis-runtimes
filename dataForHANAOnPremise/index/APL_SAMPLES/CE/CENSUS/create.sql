CREATE COLUMN TABLE "APL_SAMPLES"."CENSUS" ("id" INTEGER CS_INT NOT NULL , "age" INTEGER CS_INT, "workclass" NVARCHAR(16), "fnlwgt" INTEGER CS_INT, "education" NVARCHAR(12), "education-num" INTEGER CS_INT, "marital-status" NVARCHAR(21), "occupation" NVARCHAR(17), "relationship" NVARCHAR(14), "race" NVARCHAR(18), "sex" NVARCHAR(6), "capital-gain" INTEGER CS_INT, "capital-loss" INTEGER CS_INT, "hours-per-week" INTEGER CS_INT, "native-country" NVARCHAR(26), "class" INTEGER CS_INT, PRIMARY KEY ("id")) UNLOAD PRIORITY 5  AUTO MERGE ;
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."id" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."age" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."workclass" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."fnlwgt" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."education" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."education-num" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."marital-status" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."occupation" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."relationship" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."race" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."sex" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."capital-gain" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."capital-loss" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."hours-per-week" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."native-country" is ' ';
COMMENT ON COLUMN "APL_SAMPLES"."CENSUS"."class" is ' '