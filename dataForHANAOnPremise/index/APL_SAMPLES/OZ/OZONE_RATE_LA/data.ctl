import data
into table "APL_SAMPLES"."OZONE_RATE_LA"
from 'data.csv'
    record delimited by '\n'
    field delimited by ','
    optionally enclosed by '"'
error log 'data.err'
