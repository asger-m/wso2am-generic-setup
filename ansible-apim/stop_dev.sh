gnome-terminal -- /bin/sh -c 'docker exec $WSO2AM_NAME-apim01 "/bin/sh" "/data/apim/wso2am-4.4.0/bin/api-manager.sh" -stop'
gnome-terminal -- /bin/sh -c 'docker exec $WSO2AM_NAME-apim02 "/bin/sh" "/data/apim/wso2am-4.4.0/bin/api-manager.sh" -stop'

gnome-terminal -- /bin/sh -c 'docker exec $WSO2AM_NAME-gateway01 "/bin/sh" "/data/apim-gateway/wso2am-4.4.0/bin/api-manager.sh" -Dprofile=gateway-worker -stop'
gnome-terminal -- /bin/sh -c 'docker exec $WSO2AM_NAME-gateway02 "/bin/sh" "/data/apim-gateway/wso2am-4.4.0/bin/api-manager.sh" -Dprofile=gateway-worker -stop'
#gnome-terminal -- /bin/sh -c 'docker exec apim42 "/bin/sh" "/data/apim-control-plane/wso2am-4.4.0/bin/api-manager.sh" -Dprofile=control-plane -stop'
