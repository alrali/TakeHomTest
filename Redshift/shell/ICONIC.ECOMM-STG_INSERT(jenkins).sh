#ENV=dev
set +x
################ convert the json to column ################
echo "Environment name is : ${ENV}"

sh /opt/git/repos/data-iconic/${ENV}/redshift/shell/stg_insert.sh