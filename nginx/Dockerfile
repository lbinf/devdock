FROM 192.168.11.200:5000/kalading/klddock_nginx:v1

LABEL maintainer="leibinfeng <290887098@qq.com>"

COPY nginx.conf /etc/nginx/

ADD ./startup.sh /opt/startup.sh
CMD ["/bin/bash", "/opt/startup.sh"]

EXPOSE 80 443
