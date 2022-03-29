import data
into table "APL_SAMPLES"."CUST_TRANSACTIONS"
from 'data.csv'
    record delimited by '\n'
    field delimited by ','
    optionally enclosed by '"'
error log 'data.err'
