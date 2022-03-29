import data
into table "APL_SAMPLES"."AUTO_CLAIMS_NEW"
from 'data.csv'
    record delimited by '\n'
    field delimited by ','
    optionally enclosed by '"'
error log 'data.err'
