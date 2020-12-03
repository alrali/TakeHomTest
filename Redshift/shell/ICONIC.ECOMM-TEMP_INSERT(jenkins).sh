#ENV=dev
set +x
################ Load the raw json data into the temp table ################
echo "Environment name is : ${ENV}"

sh /opt/git/repos/data-iconic/${ENV}/redshift/shell/temp_insert.sh