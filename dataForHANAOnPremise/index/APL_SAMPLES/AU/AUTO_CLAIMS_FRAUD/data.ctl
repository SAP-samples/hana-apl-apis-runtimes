import data
into table "APL_SAMPLES"."AUTO_CLAIMS_FRAUD"
from 'data.csv'
    record delimited by '\n'
    field delimited by ','
    optionally enclosed by '"'
error log 'data.err'
