#ENV=dev
set +x
LOG_FILE=$WORKSPACE/cls_tbl_`date +%Y%m%d_%H%m`.log
#ENV_POSTGRESS_DB=postgres
#ENV_POSTGRESS_HOST=ecommdemo.cy65sdz3dwwz.ap-southeast-2.rds.amazonaws.com
#ENV_POSTGRESS_PORT=5432
#ENV_POSTGRESS_USER=akolla
#ENV_POSTGRESS_PASS=Anil$198419
#The recommended approach to fetch the cedentials is from credstash file, for my testing purpose i have hard coded the credentials with in the job. Created a credstaths entries file with postgres credentials and while promoting to production credstash should be updated in the DynamoDB and while executing the job from jenkins credentials should be read from Credstash
#Retreiving the credentials from Credstatsh is given below
`credstash -r ap-southeast-2 -t data-${ENV}-credstash get psql_data_${ENV}_iconic_cluster_admin`
export psql_cmd="psql -d ${ENV_POSTGRESS_DB} -h ${ENV_POSTGRESS_HOST} -p ${ENV_POSTGRESS_PORT} -U ${ENV_POSTGRESS_USER}"
export PGPASSWORD=$ENV_POSTGRESS_PASS
rtn=$(echo "select iconic.sp_cls_insert();" | $psql_cmd | awk 'FNR == 3 {print}' | tr -d ' ')
echo "Return Value: ${rtn} "
if [ $rtn -gt 0 ]; then
echo "Error while Loading data from staging to clean staging"
exit 1
fi
