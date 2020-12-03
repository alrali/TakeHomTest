#!/usr/bin/env bash
#ENV=dev
set +x
LOG_FILE=$WORKSPACE/iconic_ecomm_kpi`date +%Y%m%d_%H%m`.log
printf "Job started at" "`TZ=Australia/Sydney date`"

#ENV_POSTGRESS_DB=postgres
#ENV_POSTGRESS_HOST=ecommdemo.cy65sdz3dwwz.ap-southeast-2.rds.amazonaws.com
#ENV_POSTGRESS_PORT=5432
#ENV_POSTGRESS_USER=akolla
#ENV_POSTGRESS_PASS=Anil$198419
#The recommended approach to fetch the cedentials is from credstash file, for my testing purpose i have hard coded the credentials with in the job. Created a credstaths entries file with postgres credentials and while promoting to production credstash should be updated in the DynamoDB and while executing the job from jenkins credentials should be read from Credstash
#Retreiving the credentials from Credstatsh is given below
`credstash -r ap-southeast-2 -t data-${ENV}-credstash get psql_data_${ENV}_iconic_cluster_admin` # To retreive Postgres credentials#

export psql_cmd="psql -d ${ENV_POSTGRESS_DB} -h ${ENV_POSTGRESS_HOST} -p ${ENV_POSTGRESS_PORT} -U ${ENV_POSTGRESS_USER}"
export PGPASSWORD=$ENV_POSTGRESS_PASS

rtn=$(echo "select * from iconic.sp_iconic_ecomm_kpi();" | $psql_cmd | awk 'FNR == 3 {print}' | tr -d ' ')
echo " "
echo "Return ValueTotal_Revenue|Female_Percentage|Ios_Andriod_Desk_Avg_Revenue: ${rtn} "
echo " "

LOG_FILE=Marketable_`date +%Y%m%d_%H%m`.log
outfile=Marketable_`date +%Y%m%d_%H%M%S`.csv

echo "Get the mens marketable customers from the clean satging table and writing it into ${outfile}"
# Assuming is_newsletter_subscriber Yes means customer opted for communication 
sql_query="\copy (select distinct customer_id from iconic.cls_EcommTrans where male_items > 0 and is_newsletter_subscriber = 'Y') TO ${outfile}  ;"

echo ${sql_query} | ${psql_cmd} >> $LOG_FILE 2>&1

if grep -i 'Error' $LOG_FILE
then echo "### Error while querying the data ###"
rm $LOG_FILE
exit 1
else
rm $LOG_FILE
echo "### Data written successfully to ${outfile} ###"
fi

echo "Uploading the output file to S3:"

S3_DESTINATION_LOCATION="data-${ENV}-iconic-demo/outbound"
#AWS CLI move command to transfer the file from Jenkins workspace to S3
aws s3 mv ${outfile} s3://${S3_DESTINATION_LOCATION}/${outfile}
if [ $? -ne 0 ]; then
echo "File upload for ${outfile} to S3 Failed"
rm ${outfile}
exit 1
else
echo "File ${outfile} uploaded to S3 bucket successfully !"
fi

echo "Job completed at: `TZ=Australia/Sydney date`"