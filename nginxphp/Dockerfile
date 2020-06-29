FROM dev-php71-nginx:v1

LABEL maintainer="leibinfeng <290887098@qq.com>"

RUN rm -rf /usr/bin/supervisord &&  yum -y install supervisor

ADD ./supervisord.conf /etc/supervisord.conf
#ADD ./startup.sh /opt/startup.sh
#CMD ["/bin/bash", "/opt/startup.sh"]

EXPOSE 80 443
