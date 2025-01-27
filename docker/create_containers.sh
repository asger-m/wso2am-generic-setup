export WSO2AM_NAME=dev
export WSO2AM_DOMAIN=test.dk
WSO2AM_DOMAIN_NAME=future
WSO2AM_DOMAIN_EXT=dk
WSO2AM_IP_PRE=173.30

docker stop $WSO2AM_NAME-db
docker stop $WSO2AM_NAME-apim01
docker stop $WSO2AM_NAME-apim02
docker stop $WSO2AM_NAME-gateway01
docker stop $WSO2AM_NAME-gateway02
docker stop $WSO2AM_NAME-apim
docker stop $WSO2AM_NAME-gateway

docker rm $WSO2AM_NAME-db
docker rm $WSO2AM_NAME-apim01
docker rm $WSO2AM_NAME-apim02
docker rm $WSO2AM_NAME-gateway01
docker rm $WSO2AM_NAME-gateway02
docker rm $WSO2AM_NAME-apim
docker rm $WSO2AM_NAME-gateway

docker network rm $WSO2AM_DOMAIN
docker network create $WSO2AM_DOMAIN --subnet=$WSO2AM_IP_PRE.0.0/16

unzip ./ansible-apim/files/packs/wso2am-4.3.0.zip "wso2am-4.3.0/dbscripts/*" -d ansible-apim/files/dbscripts/
mv ansible-apim/files/dbscripts/wso2am-4.3.0/dbscripts/* ansible-apim/files/dbscripts/
rm -r ansible-apim/files/dbscripts/wso2am-4.3.0

docker run -p 3306:3306 --name $WSO2AM_NAME-db --network $WSO2AM_DOMAIN --ip $WSO2AM_IP_PRE.0.10 -e MYSQL_ROOT_PASSWORD=root -d mysql:8.0
sleep 10
docker exec $WSO2AM_NAME-db rmdir dbscripts --ignore-fail-on-non-empty
sleep 5
docker exec $WSO2AM_NAME-db mysql -u root --password=root -e "SET GLOBAL max_connections = 512;"
sleep 5
docker exec $WSO2AM_NAME-db mkdir dbscripts
docker cp ./ansible-apim/files/dbscripts/mysql.sql $WSO2AM_NAME-db:/dbscripts/shared.sql
docker cp ./ansible-apim/files/dbscripts/apimgt/mysql.sql $WSO2AM_NAME-db:/dbscripts/apimgt.sql
docker exec $WSO2AM_NAME-db mysql -u root --password=root -e "CREATE DATABASE SHARED_DB CHARACTER SET latin1 COLLATE latin1_general_cs;"
docker exec $WSO2AM_NAME-db mysql -u root --password=root -e "CREATE DATABASE APIM_DB CHARACTER SET latin1 COLLATE latin1_general_cs;"
sleep 10
docker exec $WSO2AM_NAME-db mysql -u root --password=root --database=SHARED_DB -e "source /dbscripts/shared.sql"
docker exec $WSO2AM_NAME-db mysql -u root --password=root --database=APIM_DB -e "source /dbscripts/apimgt.sql"
sleep 3
docker exec $WSO2AM_NAME-db mysql -u root --password=root -e "CREATE USER 'wso2_dbadmin'@'$WSO2AM_IP_PRE.0.%' identified by '123456'"
docker exec $WSO2AM_NAME-db mysql -u root --password=root -e "GRANT ALL ON SHARED_DB.* TO 'wso2_dbadmin'@'$WSO2AM_IP_PRE.0.%'"
docker exec $WSO2AM_NAME-db mysql -u root --password=root -e "GRANT ALL ON APIM_DB.* TO 'wso2_dbadmin'@'$WSO2AM_IP_PRE.0.%'"
sleep 3

echo #build ubuntu_ssh template: docker build -t ubuntu_new_ssh $PWD/ubuntu_new_ssh


docker run -d --name $WSO2AM_NAME-apim01 --network $WSO2AM_DOMAIN \
-v $PWD/logs/apim01:/data/logs \
--ip $WSO2AM_IP_PRE.0.21 ubuntu_new_ssh
docker run -d --name $WSO2AM_NAME-apim02 --network $WSO2AM_DOMAIN \
-v $PWD/logs/apim02:/data/logs \
--ip $WSO2AM_IP_PRE.0.22 ubuntu_new_ssh
docker run -d --name $WSO2AM_NAME-gateway01 --network $WSO2AM_DOMAIN \
-v $PWD/logs/gateway01:/data/logs \
--ip $WSO2AM_IP_PRE.0.31 ubuntu_new_ssh
docker run -d --name $WSO2AM_NAME-gateway02 --network $WSO2AM_DOMAIN \
-v $PWD/logs/gateway02:/data/logs \
--ip $WSO2AM_IP_PRE.0.32 ubuntu_new_ssh


rm $PWD/ansible-apim/files/security/$WSO2AM_NAME.jks
keytool -genkey -alias wso2carbon -keyalg RSA -keysize 2048 -keystore $PWD/ansible-apim/files/security/$WSO2AM_NAME.jks -dname "CN=*.$WSO2AM_DOMAIN, OU=IT,O=$WSO2AM_DOMAIN_NAME,L=$WSO2AM_DOMAIN_EXT" -ext "SAN=DNS:$WSO2AM_NAME-apim01.$WSO2AM_DOMAIN,DNS:$WSO2AM_NAME-apim02.$WSO2AM_DOMAIN,DNS:$WSO2AM_NAME-apim.$WSO2AM_DOMAIN,DNS:$WSO2AM_NAME-gateway01.$WSO2AM_DOMAIN,DNS:$WSO2AM_NAME-gateway02.$WSO2AM_DOMAIN,DNS:$WSO2AM_NAME-gateway.$WSO2AM_DOMAIN,DNS:localhost" -storepass wso2carbon -keypass wso2carbon
keytool -export -alias wso2carbon -keystore $PWD/ansible-apim/files/security/$WSO2AM_NAME.jks -storepass wso2carbon -file $PWD/ansible-apim/files/security/$WSO2AM_NAME-cert.pem -rfc
keytool -importkeystore \
 -srckeystore $PWD/ansible-apim/files/security/$WSO2AM_NAME.jks \
 -destkeystore $PWD/ansible-apim/files/security/$WSO2AM_NAME.p12 \
 -deststoretype PKCS12 \
 -srcalias wso2carbon \
 -srcstorepass wso2carbon \
 -deststorepass wso2carbon \
 -srckeypass wso2carbon \
 -destkeypass wso2carbon \
 -noprompt
openssl pkcs12 \
 -in $PWD/ansible-apim/files/security/$WSO2AM_NAME.p12 \
 -passin pass:wso2carbon \
 -nocerts -nodes \
 -out $PWD/ansible-apim/files/security/$WSO2AM_NAME-key.pem

envsubst '$WSO2AM_NAME,$WSO2AM_DOMAIN' < docker/nginx-apim.conf > nginx/$WSO2AM_NAME-apim.conf
envsubst '$WSO2AM_NAME,$WSO2AM_DOMAIN' < docker/nginx-gateway.conf > nginx/$WSO2AM_NAME-gateway.conf

echo #add ip and hostnames to /etc/hosts
echo #sudo gedit /etc/hosts
echo  "" | sudo tee -a /etc/hosts
echo  "# Begin - WSO2 API Manager" | sudo tee -a /etc/hosts
echo "$WSO2AM_IP_PRE.0.21     $WSO2AM_NAME-apim01.$WSO2AM_DOMAIN" | sudo tee -a /etc/hosts
echo "$WSO2AM_IP_PRE.0.22     $WSO2AM_NAME-apim02.$WSO2AM_DOMAIN" | sudo tee -a /etc/hosts
echo "$WSO2AM_IP_PRE.0.31     $WSO2AM_NAME-gateway01.$WSO2AM_DOMAIN" | sudo tee -a /etc/hosts
echo "$WSO2AM_IP_PRE.0.32     $WSO2AM_NAME-gateway02.$WSO2AM_DOMAIN" | sudo tee -a /etc/hosts
echo "$WSO2AM_IP_PRE.0.20     $WSO2AM_NAME-apim.$WSO2AM_DOMAIN" | sudo tee -a /etc/hosts
echo "$WSO2AM_IP_PRE.0.30     $WSO2AM_NAME-gateway.$WSO2AM_DOMAIN" | sudo tee -a /etc/hosts
echo  "# End - WSO2 API Manager" | sudo tee -a /etc/hosts

docker run -d --name $WSO2AM_NAME-apim --network $WSO2AM_DOMAIN \
 -v $PWD/ansible-apim/files/security/$WSO2AM_NAME-cert.pem:/etc/nginx/ssl/$WSO2AM_NAME-cert.pem \
 -v $PWD/ansible-apim/files/security/$WSO2AM_NAME-key.pem:/etc/nginx/ssl/$WSO2AM_NAME-key.pem \
 -v $PWD/nginx/$WSO2AM_NAME-apim.conf:/etc/nginx/conf.d/http.conf \
 --ip $WSO2AM_IP_PRE.0.20 nginx

 docker run -d --name $WSO2AM_NAME-gateway --network $WSO2AM_DOMAIN \
 -v $PWD/ansible-apim/files/security/$WSO2AM_NAME-cert.pem:/etc/nginx/ssl/$WSO2AM_NAME-cert.pem \
 -v $PWD/ansible-apim/files/security/$WSO2AM_NAME-key.pem:/etc/nginx/ssl/$WSO2AM_NAME-key.pem \
 -v $PWD/nginx/$WSO2AM_NAME-gateway.conf:/etc/nginx/conf.d/http.conf \
 --ip $WSO2AM_IP_PRE.0.30 nginx

sshpass -p root ssh root@$WSO2AM_NAME-apim01.$WSO2AM_DOMAIN -o StrictHostKeyChecking=accept-new -t 'exit'
sshpass -p root ssh root@$WSO2AM_NAME-apim02.$WSO2AM_DOMAIN -o StrictHostKeyChecking=accept-new -t 'exit'
sshpass -p root ssh root@$WSO2AM_NAME-gateway01.$WSO2AM_DOMAIN -o StrictHostKeyChecking=accept-new -t 'exit'
sshpass -p root ssh root@$WSO2AM_NAME-gateway02.$WSO2AM_DOMAIN -o StrictHostKeyChecking=accept-new -t 'exit'
