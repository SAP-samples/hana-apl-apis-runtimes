CREATE COLUMN TABLE "APL_SAMPLES"."MOVIES_ATTRIBUTES" ("FILM" NVARCHAR(50) NOT NULL , "ATTRIBUTE" NVARCHAR(80) NOT NULL , PRIMARY KEY ("FILM", "ATTRIBUTE")) UNLOAD PRIORITY 5  AUTO MERGE 