#ENV=dev
set +x
`credstash -r ap-southeast-2 -t data-{ENV}-credstash get redshift_data_${ENV}_iconic_admin`
`credstash -r ap-southeast-2 -t data-${ENV}-credstash get s3-data-${ENV}-iconic-exports`
export psql_cmd="psql -d ${ENV_REDSHIFT_DB} -h ${ENV_REDSHIFT_HOST} -p ${ENV_REDSHIFT_PORT} -U ${ENV_REDSHIFT_USER}"
export PGPASSWORD=$ENV_REDSHIFT_PASS

export TIMESTAMP=$( date +"%Y%m%d_%H%M" )

LOG_FILE=$WORKSPACE/temp_insert_${TIMESTAMP}.log
echo "Log file is: ${LOG_FILE}"

S3_SOURCE_LOCATION="data-{ENV}-iconic-demo/inbound"
# Assuming is_newsletter_subscriber Yes means customer opted for communication 
QUERY="COPY iconic.temp_ecommtrans_json FROM 's3://${S3_DESTINATION_LOCATION}/data.json'
       CREDENTIALS 'aws_access_key_id={AWS_ACCESS_KEY_ID};aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}'"

echo ${QUERY} | ${psql_cmd} > ${LOG_FILE} 2>&1
  
  if [ ! -z "$(grep ERROR $LOG_FILE)" ] ; then
    echo "error occurred while loading the data into temp table"
    exit 1  
  fi  
  
