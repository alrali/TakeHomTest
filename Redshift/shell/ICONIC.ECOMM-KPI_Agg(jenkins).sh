#ENV=dev
set +x
################ Execute final aggregate queries ################
echo "Environment name is : ${ENV}"

sh /opt/git/repos/data-iconic/${ENV}/redshift/shell/kpi_agg.sh