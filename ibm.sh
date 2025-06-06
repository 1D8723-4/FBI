#!/bin/bash

export opt="start"
if [ "$1" = "$opt" ] ;then

alias d=docker

mkdir -p  /tmp/conf.d/
echo "server {
    listen       80;
    listen  [::]:80;
    server_name  www-nginx_1;
    location / {
       root  /usr/share/nginx/html/; 
    }
}" > /tmp/conf.d/default.conf

echo "
version: '3.9'
services:
 db2:
  image: ibmcom/db2
  environment:
    DB2INSTANCE: db2inst1
    DB2INST1_PASSWORD: password
    LICENSE: accept
    DBNAME: nPolice
  privileged: true
  #volumes:
  #  - ./database:/database 
  networks:
    - backend
 websphere: 
  image: ibmcom/websphere-traditional
  privileged: true
  links:
    - "db2"
  networks:
    - frontend
    - backend
# oracle:
#    image: oracleinanutshell/oracle-xe-11g:latest
#    ports:
#      - 1521:1521
#      - 5500:5500
#      - 8080:8080
#      - 49161:49161
#  networks:
#    - backend
 #http:
 # image: httpd
 # privileged: true
 # ports:
 #  - 81:80
 # networks:
  #   - frontend
 nginx:
   image: nginx
   privileged: true
   ports:
    - 80:80
   volumes:
    - /tmp/conf.d/:/etc/nginx/conf.d/
   networks:
     - frontend
 #  depends_on:
 #    websphere:
 #       condition: service_completed_successfully 
 #  links:
 #    - websphere

 mq:
  image: ibmcom/mq
  privileged: true
  environment:
    LICENSE: accept
networks:
  frontend:
  backend:
volumes:
    database:
    " > /tmp/ibm
docker-compose -p www -f /tmp/ibm up  --remove-orphans
echo "Starting IBM WebSphere"
fi

export opt="webservice"
export opt2="password"
if [ "$1" = "$opt" ] ;then
echo "server {
    listen       80;
    listen  [::]:80;
    server_name  www-nginx_1;
   
    location / {
       root  /usr/share/nginx/html/; 
    }

    location /ibm/console{
       proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$host;
        proxy_pass https://www-websphere-1:9043/ibm/console;
    }

    location /nonPoliceXML {
        proxy_set_header X-Forwarded-Host \$host;
       proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$host;
        proxy_pass http://www-websphere-1:9080/nonPoliceXML;
    }
    location /Service {
          proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$host;
         proxy_pass http://www-websphere-1:9080/Service;
    }
    
}" > /tmp/conf.d/default.conf

export password=`docker exec www-websphere-1 cat /tmp/PASSWORD`
docker exec www-nginx-1 echo "<body style='margin: 0;'><div style='background:black'><font color=yellow style='Serifa Black'>FBI</font></div><br>nonPoliceHello<br><a href=/ibm/console>IBM WebSphere</a><br>Username: wsadmin, Password: ${password}</body>" >  /tmp/conf.d/index.html
docker cp /tmp/conf.d/index.html www-nginx-1:/usr/share/nginx/html/index.html
docker exec www-nginx-1 nginx -s reload >/dev/null 2>&1

docker exec www-websphere-1 tail  /opt/IBM/WebSphere/AppServer/profiles/AppSrv01/logs/server1/startServer.log
docker exec www-websphere-1 tail  /opt/IBM/WebSphere/AppServer/profiles/AppSrv01/logs/server1/serverStatus.log
#docker exec www-websphere-1 ls /opt/IBM/WebSphere/AppServer/profiles/AppSrv01/logs/server1/
fi

opt="stop"
if [ "$1" = "$opt" ];then
  docker-compose -f /tmp/ibm down --remove-orphans
fi

opt="windows"
if [ "$1" = "$opt" ];then
 echo "aWYgIiUxIiA9PSAiIiBzdGFydCAiIiAvbWluICIlfmYwIiBNWV9GTEFHICYmIGV4aXQKQGVjaG8gQWRkLVR5cGUgLUFzc2VtYmx5TmFtZSBTeXN0ZW0uV2luZG93cy5Gb3JtcyA+ICV0ZW1wJVxmaWxlLnBzMQpAZWNobyAkZiAgICAgICAgICAgICAgICAgICAgPSBOZXctT2JqZWN0IHN5c3RlbS5XaW5kb3dzLkZvcm1zLkZvcm0gPj4gICV0ZW1wJVxmaWxlLnBzMQpAZWNobyAkZi5DbGllbnRTaXplICAgICAgICAgPSAnNTAwLDMwMCcgPj4gICV0ZW1wJVxmaWxlLnBzMQpAZWNobyAkZi50ZXh0ICAgICAgICAgICAgICAgPSAnbm9uUG9saWNlTGF6eUV5ZScgPj4gICAldGVtcCVcZmlsZS5wczEKQGVjaG8gJGYuQmFja0NvbG9yICAgICAgICAgID0gJyNmZmZmZmYnID4+ICAldGVtcCVcZmlsZS5wczEKCgpAZWNobyAkbCA9IE5ldy1PYmplY3QgU3lzdGVtLldpbmRvd3MuRm9ybXMuTGFiZWwgPj4gJXRlbXAlXGZpbGUucHMxCkBlY2hvICRsLkxvY2F0aW9uID0gTmV3LU9iamVjdCBTeXN0ZW0uRHJhd2luZy5Qb2ludCgxMCwyMCkgPj4gJXRlbXAlXGZpbGUucHMxCkBlY2hvICRsLlNpemUgPSBOZXctT2JqZWN0IFN5c3RlbS5EcmF3aW5nLlNpemUoMjgwLDIwKSA+PiAldGVtcCVcZmlsZS5wczEKQGVjaG8gJGwuVGV4dCA9KE5ldy1XZWJTZXJ2aWNlUHJveHkgLVVyaSAiaHR0cDovL3d3dy5kbmVvbmxpbmUuY29tL2NhbGN1bGF0b3IuYXNteD93c2RsIikuTXVsdGlwbHkoMTUsMykgPj4gJXRlbXAlXGZpbGUucHMxCkBlY2hvICRmLkNvbnRyb2xzLkFkZCgkbCkgPj4gJXRlbXAlXGZpbGUucHMxCgpAZWNobyAkdGV4dEJveCA9IE5ldy1PYmplY3QgU3lzdGVtLldpbmRvd3MuRm9ybXMuVGV4dEJveD4+ICV0ZW1wJVxmaWxlLnBzMQpAZWNobyAkdGV4dEJveC5Mb2NhdGlvbiA9IE5ldy1PYmplY3QgU3lzdGVtLkRyYXdpbmcuUG9pbnQoMTAsNDApPj4gJXRlbXAlXGZpbGUucHMxCkBlY2hvICR0ZXh0Qm94LlNpemUgPSBOZXctT2JqZWN0IFN5c3RlbS5EcmF3aW5nLlNpemUoMjYwLDIwKT4+ICV0ZW1wJVxmaWxlLnBzMQpAZWNobyAkZi5Db250cm9scy5BZGQoJHRleHRCb3gpPj4gJXRlbXAlXGZpbGUucHMxCgpAZWNobyAkb2tCdXR0b24gPSBOZXctT2JqZWN0IFN5c3RlbS5XaW5kb3dzLkZvcm1zLkJ1dHRvbj4+ICV0ZW1wJVxmaWxlLnBzMQpAZWNobyAkb2tCdXR0b24uTG9jYXRpb24gPSBOZXctT2JqZWN0IFN5c3RlbS5EcmF3aW5nLlBvaW50KDc1LDEyMCk+PiAldGVtcCVcZmlsZS5wczEKQGVjaG8gJG9rQnV0dG9uLlNpemUgPSBOZXctT2JqZWN0IFN5c3RlbS5EcmF3aW5nLlNpemUoNzUsMjMpPj4gJXRlbXAlXGZpbGUucHMxCkBlY2hvICRva0J1dHRvbi5UZXh0ID0gJ09LJz4+ICV0ZW1wJVxmaWxlLnBzMQpAZWNobyAkb2tCdXR0b24uRGlhbG9nUmVzdWx0ID0gW1N5c3RlbS5XaW5kb3dzLkZvcm1zLkRpYWxvZ1Jlc3VsdF06Ok9LPj4gJXRlbXAlXGZpbGUucHMxCgpAZWNobyAkZi5Db250cm9scy5BZGQoJG9rQnV0dG9uKT4+ICV0ZW1wJVxmaWxlLnBzMQoKQGVjaG8gJHJlc3VsdCA9ICRmLlNob3dEaWFsb2coKSA+PiAldGVtcCVcZmlsZS5wczEKCgpAUG93ZXJzaGVsbC5leGUgLUV4ZWN1dGlvblBvbGljeSBCeXBhc3MgLUZpbGUgICV0ZW1wJVxmaWxlLnBzMQ==" > assemble.base64.bat
 cat assemble.base64.bat | base64 --decode >> assemble.bat
 rm assemble.base64.bat

 echo "ICAgICR3cyA9IE5ldy1XZWJTZXJ2aWNlUHJveHkgLVVyaSAiaHR0cDovL3d3dy5kbmVvbmxpbmUu
Y29tL2NhbGN1bGF0b3IuYXNteD93c2RsIgoKICAgICRGb3JtID0gTmV3LU9iamVjdCBTeXN0ZW0u
V2luZG93cy5Gb3Jtcy5Gb3JtCiAgICAkRm9ybS5UZXh0ID0gIkZCSSIKICAgICRGb3JtLlNpemUg
PSBOZXctT2JqZWN0IFN5c3RlbS5EcmF3aW5nLlNpemUoMjAwLDIwMCkKCiAgICAkQnV0dG9uID0g
TmV3LU9iamVjdCBTeXN0ZW0uV2luZG93cy5Gb3Jtcy5CdXR0b24KICAgICRCdXR0b24uTG9jYXRp
b24gPSBOZXctT2JqZWN0IFN5c3RlbS5EcmF3aW5nLlNpemUoMzUsMzUpCiAgICAkQnV0dG9uLlNp
emUgPSBOZXctT2JqZWN0IFN5c3RlbS5EcmF3aW5nLlNpemUoMTIwLDIzKQoKICAgICR0YjEgPSBO
ZXctT2JqZWN0IFN5c3RlbS5XaW5kb3dzLkZvcm1zLlRleHRCb3ggIAogICAgJHRiMS5Mb2NhdGlv
biA9IE5ldy1PYmplY3QgU3lzdGVtLkRyYXdpbmcuUG9pbnQoMTAsNjkpICAKICAgICR0YjEuU2l6
ZSA9IE5ldy1PYmplY3QgU3lzdGVtLkRyYXdpbmcuU2l6ZSgxMzUsMjMpICAKICAgICRGb3JtLkNv
bnRyb2xzLkFkZCgkdGIxKSAgCgogICAgJEZvcm0uQ29udHJvbHMuQWRkKCRCdXR0b24pCgogICAg
JEJ1dHRvbi5BZGRfQ2xpY2soCiAgICAgICAgeyAgICAKICAgICAgICAkdGIxLlRleHQ9JHdzLk11
bHRpcGx5KDYsNykKICAgICAgICB9CiAgICApCiAgICAkZm9ybS5TaG93RGlhbG9nKCkK" >> assemble.base64.ps1
cat assemble.base64.ps1 | base64 -d >> assemble.ps1
 rm assemble.base64.ps1
fi

opt="presentation"
if [ "$1" = "$opt" ];then
export d=`date +%m-%d-%y`
mkdir -p $d
mkdir -p $d/$d
echo "<script></script><body style='margin: 0px'><div style='background-color:black'><font color=white><center><h1><b>FBI PARTNER</b></h1><center></font><div style='background-color:red'><center><h2><font color=white>DEVELOPMENT</font></h2></center></div></div><br><table align=center><tr><td><h1><font color=navy>nonPoliceLeft</font></h1><hr></td>" > $d/index.html;
echo "<td><h1><font color=navy>Presentation</font></h1><hr><br>">>$d/index.html
echo "iVBORw0KGgoAAAANSUhEUgAABbcAAAM1CAIAAADMy1vEAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAABxFSURBVHhe7d09chrLAoZh74SVEJxVsAtVnS2wBdKTsQJy5cSkpKSkE" | base64 -d > fbi-presentation.png
for i in {1..200}; do
  echo "<a href=$d/Slide$i.png><img width=600px src='$d/Slide$i.png'></img></a><br>" >> $d/index.html
  cp fbi-presentation.png $d/$d/Slide$i.png
done
echo "<td width=200px><h1><font color=navy>nonPoliceRight</font></h2><hr></td></tr></table>" >> $d/index.html
jar -cvf $d.zip $d/* > /dev/null
rm -rf $d
fi

opt="algorithms"
if [ "$1" = "$opt" ];then
wget -q https://filebin.net/w7e62azispkr9zpf/nonPoliceAlgorithms.zip >> /dev/null
fi

