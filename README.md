
Spin up the below services on AWS Free Tier account

1. EMR cluster(IconicEcommDemo) with spark running on it(1 master and 2 workers - M4 Large)
2.Created below S3 buckets 
   2.1 data-dev-iconic-demo/inbound - For the incoming data(copy data.json file)2.2 data-dev-iconic-demo/outbound - For outbound files(Push men’s marketable customers Marketable_YYYYMMDDHHMMSS.csv)

 RDS instance with Postgres engine3.1 Created database with the name as postgres and schema name ass iconic3.2 Created below tables     3.2.1. iconic.stg_ecommtrans - staging table after converting the json key value pairs to columns and rows     3.2.2. iconic.cls_ecommtrans - clean staging table after correcting the data anomalies and proper data type conversions     3.2.3. iconic.kpi_agg - Table to have the ag results (optional)               Git location for the table definitions:                   3.3 Created below stored proceudures     3.3.1. iconic.sp_cls_insert() - Load the data from iconic.stg_ecommtrans to iconic.cls_ecommtrans     3.3.2. iconic.sp_iconic_ecomm_kpi() - Retrieves the aggregated results, and to load the aggregated results into iconic.kpi_agg              Git location for the stored procedures:  

Redshift cluster with 1 node4.1 Created database with the name as  iconicdemo, and schema name as iconic4.2 Created tables iconic.stg_ecommtrans, iconic.cls_ecommtrans, and iconic.kpi_agg            Git location for the table definitions:  

Created credstash files with the connection details for postgres, redshift, and AWS access keys5.1 Postgres - postgres_credstatsh(Git location: )5.2 Redshift - Redshift Credstash(Git location:  )5.3 AWS keys - Redshift Exports(Git location:  )

Tools:

IntelliJ IDEA to develop the scala code, and to build the Spark JAR file	

Pgadmin to connect to postgres

Aginity to connect to Redshift

Jenkins to schedule the jobs and create YML files

Git for code repository

  (Postgres and Redshift artifacts) 

  (Spark code)

Note : Considering its an AWS env assuming Credstash and Jenkins are configured to run the jobs

Designed and implemented the solution in below approaches

Approach 1


Created Spark app( ) using Intellij IDEA , and below are the steps1.1 Read the data.json file from S3 bucket data-dev-iconic-demo/inbound1.2 Load the json file into data frame1.3 Create the staging table in postgres (iconic.stg_ecommtrans) by converting the data frame into column and rows1.4 Build the JAR file using SBT1.5 Upload the JAR file to S3 bucket data-dev-iconic-demo/inbound1.6 ssh to the EMR master using ppk key (iconcikeypair.ppk)  hadoop@ec2-3-25-205-213.ap-southeast-2.compute.amazonaws.com1.7 submit the spark jar file using spark submit from the master node terminal (spark-submit ./jsonparse_2.11-0.1.jar)  

Created database function(iconic.sp_cls_insert()) to load the data from staging table(iconic.stg_ecommtrans) into clean staging table (iconic.cls_ecommtrans)Data Anomalies i. There are quite many records days_since_first_order and days_since_last_order are swapped. Corrected such records with the below case statement

case when CAST(days_since_first_order AS integer) > CAST(days_since_last_order AS integer) then  CAST(days_since_first_order AS integer)         else CAST(days_since_last_order AS integer)end as days_since_first_order,case when CAST(days_since_last_order AS integer) > CAST(days_since_first_order AS integer) then  CAST(days_since_first_order AS integer)        else CAST(days_since_last_order AS integer)end as days_since_last_order,ii. Both the discount attributes(average_discount_onoffer and average_discount_used) are not at the same granularity level. In many cases discount value is way higher than the revenue, which obviously not correct. Corrected the discount anomalies by dividing the average_discount_used with 10000, which making both the discount attributes are meaningful according to the definition

CAST(average_discount_used/10000     AS float  )

For instance customer_id = '5a0f5829739e28b66cfc3f94170103d8' where average_discount_onoffer is 0.0799 and average_discount_used is 799.233. Its evident that  average_discount_used is multiplied by 10000 with average_discount_onoffer and then rounded off to the nearest integer. Having no other discount applied for this customer the average_discount_onoffer and average_discount_used should be the same, which is 0.0799. Considering a discount of 0.0799 on 244 is not realistic, but atleast logically its making sense                                                                                                                                                                                                                        Also verified the data to see any data anomalies

Could see multiple records for the same customer

Is items equals to the sum of(male_itemes,female_items,unisex_items) - Matching

Is orders equals to the sum of (msite_orders,desktop_orders,android_orders,ios_orders,other_device_orders) - Matching

Is female_items equals to the sum of (wapp_items,wftw_items,wacc_items,wspt_items) - Not matching, but curvy_items and sacc_items are not either male or female items, can't confirm exactly this as a data issue

Is male_items equals to the sum of (mapp_items,macc_items,mftw_items,mspt_items) - Not matching, but curvy_items and sacc_items are not either male or female items, can't confirm exactly this as a data issue

3.  Created database function(iconic.sp_iconic_ecomm_kpi()) to calculate the KPIs      3.1 Insert the aggregated query results into a table(iconic.kpi_agg), and  also print the results on to the Jenkins console.

         What was the total revenue to the nearest dollar for customers who have paid by credit card?

           select round(sum(revenue))  as cc_revenue from iconic.cls_EcommTrans where cc_payments > 0 - 50372282

         What percentage of customers who have purchased female items have paid by credit card?

           select round((sum(CASE WHEN female_items > 0 and cc_payments > 0 THEN 1 ELSE 0 END)* 100 )                                /(select count(distinct customer_id) from iconic.cls_EcommTrans where female_items> 0)                              ) as Female_Percentage          from iconic.cls_EcommTrans - 65

        What was the average revenue for customers who used either iOS, Android or Desktop?

          select avg(revenue) from iconic.cls_ecommtrans  where  (desktop_orders > 0 or android_orders > 0 or ios_orders > 0) - 1484.8900

       We want to run an email campaign promoting a new mens luxury brand. Can you provide a list of customers we should send to?

              select distinct customer_id from iconic.cls_EcommTrans where male_items > 0 and is_newsletter_subscriber = 'Y'(Assuming is_newsletter_subscriber Yes means    customer opted to receive the communication) - 7463

       

Shell Scriptscls_insert.sh - Wrapper to execute the procedure iconic.sp_cls_insert() to load the data from staging to clean staging                       Git Location:  kpi_agg.sh - Wrapper to execute the procedute iconic.sp_iconic_ecomm_kpi() to load the aggregated results into a table, and print the results on the Jenkins console. Also upload the mens marketable list to S3 using AWS CLI                       Git Location: 

Jenkin JobsICONIC.ECOMM-CLS_INSERT- To execute cls_insert.sh(Git Location: )ICONIC.ECOMM-KPI_Agg - To execute kpi_agg.sh(Git Location: )

Job Execution sequence

Execute EMR job

ICONIC.ECOMM-CLS_INSERT

ICONIC.ECOMM-KPI_Agg

Job Scheduling(considering the current requirement is batch mode)

Option 1 : If the aggregation queries and Men's luxury brand customers are need to be run on daily basis then schedule the jenkin job ICONIC.ECOMM-KPI_Agg to run say 9 am everyday, it can be defined using Jenkins Build periodically option under Build TriggersSchedule as H 9 * * 1-7

Option 2: If all the jobs are need to be run once a day. Then scheduling should be done as below1. Schedule the EMR job to run at 8 am(spinning up the cluster, execute the spark job, and then terminate the cluster)2. Define the job dependency between ICONIC.ECOMM-CLS_INSERT and ICONIC.ECOMM-KPI_Agg Say job ICONIC.ECOMM-CLS_INSERT  will  run at 9 am(Schedule as H 9 * * 1-7), and once successful completions job ICONIC.ECOMM-KPI_Agg will be triggered

Execution Strategies

Strategy 1 : Simulated the data in my current project work environment, and executed the jobs using Jenkins by reading the scripts from Git

Strategy 2 : Since Credstash and Jenkins are not configured on my AWS Tier executed the jobs manually by hard coding the credentials within the scripts

Notes :1.Provided the Jenkin YML files to migrate to the jobs higher environments(UAT/PROD etc...)2.created sub folders in Git to separate both sql and shell scripts3.Since its not a good practice to fetch the database/AWS credentials either from jenkins or from the script, i have created the credstash file with set of credentials4.Given detail level description inside the .sh files

Approach 2

Similar to Approach 1, except chosen Redshift as the Relational database. Since redshift doesn't supports stored procedures, use the sql statements inside the shell scripts to load the data from/into staging, cleaning, aggregation/copying file to S3 etc...

Shell Scriptscls_insert.sh - load the data from staging table(iconic.stg_ecommtrans) into clean staging table (iconic.cls_ecommtrans)                           Git Location: kpi_agg.sh - Insert the aggregated query results into table(iconic.kpi_agg),and print the results on to the Jenkins console. Also upload the men's marketable list to S3 using AWS CLI

                           Git Location:  

Jenkin JobsICONIC.ECOMM-CLS_INSERT- To execute cls_insert.sh(Git Location: )ICONIC.ECOMM-KPI_Agg - To execute kpi_agg.sh(Git Location:  )

Approach 3

Instead of spinning up EMR cluster, load the raw json data directly into Redshift and then using json_extract_path_text function convert the key value pairs to columns and rows. After that follow the Approach 2 steps from staging to the rest

Copy the data file (data.json) into S3 bucket data-dev-iconic-demo/inbound

Create a temp table (iconinc.temp_ecommtrans_json), and using AWS copy command store the raw json data into temp_ecommtrans_json         Git Location:  

Created a job to load the raw json data from S3 to the temp table iconinc.temp_ecommtrans_json. This job uses AWS copy command to load the data 	         Git Location:  

Created a job to convert the json data from iconinc.temp_ecommtrans_json to tabluar form and then load into staging table(iconic.stg_ecommtrans). Used Redshift json_extract_path_text function to convert the key value pairs to columns and rows         Git Location:  

Follow Approach 2 steps after the loading the data into staging table

Jenkin JobsICONIC.ECOMM-TEMP_INSERT-To execute temp_insert.sh(Git Location: )ICONIC.ECOMM-STG_INSERT-To execute stg_insert.sh(Git Location: )

Job Execution sequenceFrom job Execution perspective instead of EMR job ICONIC.ECOMM-TEMP_INSERT and ICONIC.ECOMM-STG_INSERT should be executed

ICONIC.ECOMM-TEMP_INSERT

ICONIC.ECOMM-STG_INSERT

ICONIC.ECOMM-CLS_INSERT

ICONIC.ECOMM-KPI_Agg

Job SchedulingOption 1 : If the aggregation queries and Men's luxury brand customers are need to be run on daily basis then schedule the jenkin job ICONIC.ECOMM-KPI_Agg to run say 9 am everyday, it can be defined using Jenkins Build periodically option under Build TriggersSchedule as H 9 * * 1-7

Option 2: If all the jobs are need to be run once a day. Then scheduling should be done as below1.Define the job dependency between ICONIC.ECOMM-TEMP_INSERT,ICONIC.ECOMM-STG_INSERT,ICONIC.ECOMM-CLS_INSERT and ICONIC.ECOMM-KPI_Agg Say job ICONIC.ECOMM-TEMP_INSERT  will  run at 9 am(Schedule as H 9 * * 1-7), and once successful completion remaining jobs will be executed sequentially
