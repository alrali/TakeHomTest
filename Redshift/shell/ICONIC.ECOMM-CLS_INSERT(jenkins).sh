#ENV=dev
set +x
################ Execute clean staging data ################
echo "Environment name is : ${ENV}"

sh /opt/git/repos/data-iconic/${ENV}/redshift/shell/cls_insert.sh