#ENV=dev
set +x
`credstash -r ap-southeast-2 -t data-{ENV}-credstash get redshift_data_${ENV}_iconic_admin`
export psql_cmd="psql -d ${ENV_REDSHIFT_DB} -h ${ENV_REDSHIFT_HOST} -p ${ENV_REDSHIFT_PORT} -U ${ENV_REDSHIFT_USER}"
export PGPASSWORD=$ENV_REDSHIFT_PASS

export TIMESTAMP=$( date +"%Y%m%d_%H%M" )

LOG_FILE=$WORKSPACE/stg_insert_${TIMESTAMP}.log
echo "Log file is: ${LOG_FILE}"

QUERY="insert into iconic.stg_EcommTrans
select 
json_extract_path_text(sampletext,'sacc_items'),
json_extract_path_text(sampletext,'work_orders'),
json_extract_path_text(sampletext,'female_items'),
json_extract_path_text(sampletext,'is_newsletter_subscriber'),
json_extract_path_text(sampletext,'male_items'),
json_extract_path_text(sampletext,'afterpay_payments'),
json_extract_path_text(sampletext,'msite_orders'),
json_extract_path_text(sampletext,'wftw_items'),
json_extract_path_text(sampletext,'mapp_items'),
json_extract_path_text(sampletext,'orders'),
json_extract_path_text(sampletext,'cc_payments'),
json_extract_path_text(sampletext,'curvy_items'),
json_extract_path_text(sampletext,'paypal_payments'),
json_extract_path_text(sampletext,'macc_items'),
json_extract_path_text(sampletext,'cancels'),
json_extract_path_text(sampletext,'revenue'),
json_extract_path_text(sampletext,'returns'),
json_extract_path_text(sampletext,'other_collection_orders'),
json_extract_path_text(sampletext,'parcelpoint_orders'),
json_extract_path_text(sampletext,'customer_id'),
json_extract_path_text(sampletext,'android_orders'),
json_extract_path_text(sampletext,'days_since_last_order'),
json_extract_path_text(sampletext,'vouchers'),
json_extract_path_text(sampletext,'average_discount_used'),
json_extract_path_text(sampletext,'shipping_addresses'),
json_extract_path_text(sampletext,'redpen_discount_used'),
json_extract_path_text(sampletext,'mftw_items'),
json_extract_path_text(sampletext,'days_since_first_order'),
json_extract_path_text(sampletext,'unisex_items'),
json_extract_path_text(sampletext,'home_orders'),
json_extract_path_text(sampletext,'coupon_discount_applied'),
json_extract_path_text(sampletext,'desktop_orders'),
json_extract_path_text(sampletext,'ios_orders'),
json_extract_path_text(sampletext,'apple_payments'),
json_extract_path_text(sampletext,'wspt_items'),
json_extract_path_text(sampletext,'wacc_items'),
json_extract_path_text(sampletext,'items'),
json_extract_path_text(sampletext,'mspt_items'),
json_extract_path_text(sampletext,'devices'),
json_extract_path_text(sampletext,'different_addresses'),
json_extract_path_text(sampletext,'wapp_items'),
json_extract_path_text(sampletext,'other_device_orders'),
json_extract_path_text(sampletext,'average_discount_onoffer')
from iconinc.temp_ecommtrans_json"

echo ${QUERY} | ${psql_cmd} > $LOG_FILE 2>&1

#cat /opt/git/repos/data-iconic/${ENV}/redshift/sql/cls_insert.sql | $psql_cmd > $LOG_FILE 2>&1

cat $LOG_FILE
if [ ! -z "$(grep -i ERROR $LOG_FILE)" ] ; then exit -1 ; fi

echo"Truncate the temp table"
QUERY="Truncate iconic.temp_ecommtrans_json"

echo ${QUERY} | ${psql_cmd}