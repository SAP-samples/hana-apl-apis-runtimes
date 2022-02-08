/*
 Creating two Tables Types
 (the two corresponding tables can be imported from the folder: samples/data)
*/

connect USER_APL password Password1;
set schema USER_APL;

-- For the training phase
drop type AUTO_CLAIMS_FRAUD_T;
create type AUTO_CLAIMS_FRAUD_T as table (
 claim_id        		varchar(10)   	NOT NULL,
 days_to_report        	integer     	NOT NULL,
 bodily_injury_amount	integer     	NOT NULL,
 property_damage   		integer     	NOT NULL,
 previous_claims   		integer     	NOT NULL,
 payment_method         varchar(4)		NOT NULL,
 is_rear_end_collision 	varchar(3)		NOT NULL,
 prem_amount			varchar(20)		NOT NULL,
 age	        		integer     	NOT NULL,
 gender          		varchar(6)		NOT NULL,  
 marital_status    		varchar(7)		NOT NULL,  
 income_estimate   		double			NOT NULL,
 income_category   		integer     	NOT NULL,
 policy_holder			varchar(1)		NOT NULL,
 is_fraud				varchar(3)		NOT NULL,
 PRIMARY KEY (claim_id)
);

-- For the apply phase
drop type AUTO_CLAIMS_NEW_T;
create type AUTO_CLAIMS_NEW_T as table (
 claim_id        		varchar(10)   	NOT NULL,
 days_to_report        	integer     	NOT NULL,
 bodily_injury_amount	integer     	NOT NULL,
 property_damage   		integer     	NOT NULL,
 previous_claims   		integer     	NOT NULL,
 payment_method         varchar(4)		NOT NULL,
 is_rear_end_collision 	varchar(3)		NOT NULL,
 prem_amount			varchar(20)	NOT NULL,
 age	        		integer     	NOT NULL,
 gender          		varchar(6)		NOT NULL,  
 marital_status    		varchar(7)		NOT NULL,  
 income_estimate   		double			NOT NULL,
 income_category   		integer     	NOT NULL,
 policy_holder			varchar(1)		NOT NULL,
 PRIMARY KEY (claim_id)
);



