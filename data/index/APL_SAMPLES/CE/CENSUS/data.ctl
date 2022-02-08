import data
into table "APL_SAMPLES"."CENSUS"
from 'data.csv'
    record delimited by '\n'
    field delimited by ','
    optionally enclosed by '"'
error log 'data.err'
