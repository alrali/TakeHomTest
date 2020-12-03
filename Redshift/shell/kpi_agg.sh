#ENV=dev
set +x
`credstash -r ap-southeast-2 -t data-{ENV}-credstash get redshift_data_${ENV}_iconic_admin`
`credstash -r ap-southeast-2 -t data-${ENV}-credstash get s3-data-${ENV}-iconic-exports`
export psql_cmd="psql -d ${ENV_REDSHIFT_DB} -h ${ENV_REDSHIFT_HOST} -p ${ENV_REDSHIFT_PORT} -U ${ENV_REDSHIFT_USER}"
export PGPASSWORD=$ENV_REDSHIFT_PASS

export TIMESTAMP=$( date +"%Y%m%d_%H%M" )

LOG_FILE=$WORKSPACE/kpi_agg_${TIMESTAMP}.log
echo "Log file is: ${LOG_FILE}"
#Option 1 - Execute the select query and print the results on Jenkins console
#QUERY="SELECT t1.cc_revenue
#              ,t2.female_percentage
#              ,t3.ios_andriod_ios_desk_revenue
#   from 
#       /*What was the total revenue to the nearest dollar for customers who have paid by credit card?*/
#	   (select round(sum(revenue))  as cc_revenue 
#         from iconic.cls_EcommTrans where cc_payments > 0
#		) t1
#   cross join 
#        /*What percentage of customers who have purchased female items have paid by credit card?*/  
#       (select round((sum(CASE WHEN female_items > 0 and cc_payments > 0 THEN 1 ELSE 0 END)* 100 )
#                            /(select count(distinct customer_id) from iconic.cls_EcommTrans where female_items> 0)
#						   ) as Female_Percentage
#               from iconic.cls_EcommTrans
#			   ) t2
#   cross join 
#        /*What was the average revenue for customers who used either iOS, Android or Desktop?*/
#        (select avg(revenue) from iconic.cls_ecommtrans  where  (desktop_orders > 0 or android_orders > 0 or ios_orders > 0) 
#		 )t3"
#echo ${QUERY} | ${psql_cmd} > $LOG_FILE 2>&1



#Option 2 - Insert the aggregates into a table and then print the results of the aggregated
#table in the Jenkins console

QUERY="INSERT INTO iconic.kpi_agg(Total_Revenue,
                           Female_Percentage,
						   Ios_Andriod_Desk_Avg_Revenue)
                           
        SELECT t1.cc_revenue
              ,t2.female_percentage
              ,t3.ios_andriod_ios_desk_revenue
   from 
       /*What was the total revenue to the nearest dollar for customers who have paid by credit card?*/
	   (select round(sum(revenue))  as cc_revenue 
         from iconic.cls_EcommTrans where cc_payments > 0
		) t1
   cross join 
        /*What percentage of customers who have purchased female items have paid by credit card?*/  
       (select round((sum(CASE WHEN female_items > 0 and cc_payments > 0 THEN 1 ELSE 0 END)* 100 )
                            /(select count(distinct customer_id) from iconic.cls_EcommTrans where female_items> 0)
						   ) as Female_Percentage
               from iconic.cls_EcommTrans
			   ) t2
   cross join 
        /*What was the average revenue for customers who used either iOS, Android or Desktop?*/
        (select avg(revenue) from iconic.cls_ecommtrans  where  (desktop_orders > 0 or android_orders > 0 or ios_orders > 0) 
		 )t3"
  
echo ${QUERY} | ${psql_cmd} > $LOG_FILE 2>&1

cat $LOG_FILE
if [ ! -z "$(grep -i ERROR $LOG_FILE)" ] ; then exit -1 ; fi 

  QUERY="SELECT Total_Revenue,Female_Percentage,Ios_Andriod_Desk_Avg_Revenue from iconic.kpi_agg"
  echo ${QUERY} | ${psql_cmd}
  
S3_DESTINATION_LOCATION="data-{ENV}-iconic-demo/outbound"
# Assuming is_newsletter_subscriber Yes means customer opted for communication 
QUERY="UNLOAD('select distinct customer_id from iconic.cls_EcommTrans where male_items > 0 and and is_newsletter_subscriber = 'Y'') 
         TO 's3://${S3_DESTINATION_LOCATION}/Marketable_${TIMESTAMP}.csv'
         CREDENTIALS 'aws_access_key_id={AWS_ACCESS_KEY_ID};aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}'
         PARALLEL OFF"

echo "Uploading the Mens marketable list to S3:"

echo ${QUERY} | ${psql_cmd} > ${LOG_FILE} 2>&1
  
  if [ ! -z "$(grep ERROR $LOG_FILE)" ] ; then
    echo "error occurred in UNLOAD"
    exit 1  
  fi  