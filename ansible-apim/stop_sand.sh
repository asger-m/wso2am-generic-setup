gnome-terminal -- /bin/sh -c 'docker exec apim01 "/bin/sh" "/data/gateway01/apim-gateway/wso2am-4.0.0/bin/api-manager.sh" --optimize -Dprofile=gateway-worker -stop'
gnome-terminal -- /bin/sh -c 'docker exec apim01 "/bin/sh" "/data/gateway02/apim-gateway/wso2am-4.0.0/bin/api-manager.sh" --optimize -Dprofile=gateway-worker -stop'
gnome-terminal -- /bin/sh -c 'docker exec apim01 "/bin/sh" "/data/apim01/apim-control-plane/wso2am-4.0.0/bin/api-manager.sh" --optimize -Dprofile=control-plane -stop'
gnome-terminal -- /bin/sh -c 'docker exec apim01 "/bin/sh" "/data/apim02/apim-control-plane/wso2am-4.0.0/bin/api-manager.sh" --optimize -Dprofile=control-plane -stop'

