gnome-terminal -- /bin/sh -c 'docker exec gateway42 "/bin/sh" "/data/apim-gateway/wso2am-4.3.0/bin/api-manager.sh" -Dprofile=gateway-worker -stop'
gnome-terminal -- /bin/sh -c 'docker exec apim42 "/bin/sh" "/data/apim-control-plane/wso2am-4.3.0/bin/api-manager.sh" -Dprofile=control-plane -stop'
