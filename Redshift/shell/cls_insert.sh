#ENV=dev
set +x
`credstash -r ap-southeast-2 -t data-{ENV}-credstash get redshift_data_${ENV}_iconic_admin`
export psql_cmd="psql -d ${ENV_REDSHIFT_DB} -h ${ENV_REDSHIFT_HOST} -p ${ENV_REDSHIFT_PORT} -U ${ENV_REDSHIFT_USER}"
export PGPASSWORD=$ENV_REDSHIFT_PASS

export TIMESTAMP=$( date +"%Y%m%d_%H%M" )

LOG_FILE=$WORKSPACE/STG_EcommTrans_${TIMESTAMP}.log
echo "Log file is: ${LOG_FILE}"

QUERY="insert into iconic.cls_EcommTrans
 select CAST(customer_id               AS varchar),
 case when CAST(days_since_first_order AS integer) > CAST(days_since_last_order AS integer) then  CAST(days_since_first_order AS integer)
       else CAST(days_since_last_order AS integer) end as days_since_first_order,
 case when CAST(days_since_last_order AS integer) > CAST(days_since_first_order AS integer) then  CAST(days_since_first_order AS integer)
       else CAST(days_since_last_order AS integer) end as days_since_last_order,
 CAST(is_newsletter_subscriber  AS varchar),
 CAST(orders                    AS integer),
 CAST(items                     AS integer),
 CAST(cancels                   AS integer),
 CAST(returns                   AS integer),
 CAST(different_addresses       AS integer),
 CAST(shipping_addresses        AS integer),
 CAST(devices                   AS integer),
 CAST(vouchers                  AS integer),
 CAST(cc_payments               AS integer),
 CAST(paypal_payments           AS integer),
 CAST(afterpay_payments         AS integer),
 CAST(apple_payments            AS integer),
 CAST(female_items              AS integer),
 CAST(male_items                AS integer),
 CAST(unisex_items              AS integer),
 CAST(wapp_items                AS integer),
 CAST(wftw_items                AS integer),
 CAST(mapp_items                AS integer),
 CAST(wacc_items                AS integer),
 CAST(macc_items                AS integer),
 CAST(mftw_items                AS integer),
 CAST(wspt_items                AS integer),
 CAST(mspt_items                AS integer),
 CAST(curvy_items               AS integer),
 CAST(sacc_items                AS integer),
 CAST(msite_orders              AS integer),
 CAST(desktop_orders            AS integer),
 CAST(android_orders            AS integer),
 CAST(ios_orders                AS integer),
 CAST(other_device_orders       AS integer),
 CAST(work_orders               AS integer),
 CAST(home_orders               AS integer),
 CAST(parcelpoint_orders        AS integer),
 CAST(other_collection_orders   AS integer),
 CAST(average_discount_onoffer  AS float  ),
 CAST(average_discount_used/10000     AS float  ),
 CAST(revenue                   AS float  )
 from iconic.stg_EcommTrans"

echo ${QUERY} | ${psql_cmd} > $LOG_FILE 2>&1

#cat /opt/git/repos/data-iconic/${ENV}/redshift/sql/cls_insert.sql | $psql_cmd > $LOG_FILE 2>&1

cat $LOG_FILE
if [ ! -z "$(grep -i ERROR $LOG_FILE)" ] ; then exit -1 ; fi

echo"Truncate the staging table"
QUERY="Truncate iconic.stg_EcommTrans"

echo ${QUERY} | ${psql_cmd}
