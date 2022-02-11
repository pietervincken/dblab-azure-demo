#!/bin/sh

test -f dblab.key || (az keyvault secret download --vault-name kvdblabdemo --name private -f dblab.key && chmod 0600 dblab.key)
ip=$(az network public-ip show -g rg-dblabdemo -n pip-dblabdemo --query 'ipAddress' -o tsv)

echo "Fetching credentials"
token=$(az keyvault secret show --vault-name kvdblabdemo --name token --query 'value' -o tsv)
db_admin=$(az postgres server show --name postgresql-dblabdemo-1 -g rg-dblabdemo --query administratorLogin -o tsv)
db_name=$(az postgres server show --name postgresql-dblabdemo-1 -g rg-dblabdemo --query name -o tsv)
db_username=$(echo "$db_admin@$db_name")
db_password=$(az keyvault secret show --vault-name kvdblabdemo --name password --query 'value' -o tsv)
db_fqdn=$(az postgres server show --name postgresql-dblabdemo-1 -g rg-dblabdemo --query fullyQualifiedDomainName -o tsv)
db_version=$(az postgres server show --name postgresql-dblabdemo-1 -g rg-dblabdemo --query version -o tsv)

echo "Creating configuration"
curl https://gitlab.com/postgres-ai/database-lab/-/raw/v3.0.0/configs/config.example.logical_generic.yml -sSo vm/server.yml
yq -i e ".server.verificationToken |= \"$token\"" vm/server.yml
yq -i e ".retrieval.spec.logicalDump.options.source.connection.host |= \"$db_fqdn\"" vm/server.yml
yq -i e ".retrieval.spec.logicalDump.options.source.connection.username |= \"$db_username\"" vm/server.yml
yq -i e ".retrieval.spec.logicalDump.options.source.connection.password |= \"$db_password\"" vm/server.yml
# yq -i e ".databaseContainer.dockerImage |= \"postgres:$db_version-alpine\"" vm/server.yml
# yq -i e ".databaseContainer.dockerImage |= \"postgresai/extended-postgres:$db_version\"" vm/server.yml
yq -i e ".databaseContainer.dockerImage |= \"mypostgresai\"" vm/server.yml
yq -i e ".retrieval.spec.logicalDump.options.databases = {\"dblabdemo\":{}}" vm/server.yml
yq -i e ".retrieval.spec.logicalRestore.options.databases = {\"dblabdemo\":{}}" vm/server.yml
yq -i e ".embeddedUI.host |= \"0.0.0.0\"" vm/server.yml
yq -i e ".cloning.accessHost |= \"$db_fqdn\"" vm/server.yml
yq -i e ".retrieval.spec.logicalDump.options.dumpLocation |= \"/var/lib/dblab/dblab_pool_01/dump\"" vm/server.yml
yq -i e ".retrieval.spec.logicalRestore.options.dumpLocation |= \"/var/lib/dblab/dblab_pool_01/dump\"" vm/server.yml
## Workaround for YQ behavior
sed -i '' "s/!!merge\ //g" vm/server.yml

echo "Upload files"
scp -i dblab.key $PWD/vm/install.sh adminuser@$ip:/home/adminuser/install.sh
scp -i dblab.key $PWD/vm/random.sql adminuser@$ip:/home/adminuser/random.sql
scp -i dblab.key $PWD/vm/Dockerfile adminuser@$ip:/home/adminuser/Dockerfile
scp -i dblab.key $PWD/vm/server.yml adminuser@$ip:/home/adminuser/.dblab/engine/configs/server.yml

echo "Installing all dependencies"
ssh adminuser@$ip -i dblab.key 'sh /home/adminuser/install.sh && rm /home/adminuser/install.sh'

echo "Build custom postgres image"
ssh adminuser@$ip -i dblab.key 'docker build -t mypostgresai - < Dockerfile && rm /home/adminuser/Dockerfile'

echo "Create test data on source instance"
command="PGPASSWORD=$db_password psql -f random.sql -h $db_fqdn -U $db_username -d dblabdemo && rm /home/adminuser/random.sql"
ssh adminuser@$ip -i dblab.key "$command"
