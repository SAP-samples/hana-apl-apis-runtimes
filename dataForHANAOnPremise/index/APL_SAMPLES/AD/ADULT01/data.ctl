import data
into table "APL_SAMPLES"."ADULT01"
from 'data.csv'
    record delimited by '\n'
    field delimited by ','
    optionally enclosed by '"'
error log 'data.err'
