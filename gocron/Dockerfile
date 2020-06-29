FROM dev_nginx

LABEL maintainer="leibinfeng <290887098@qq.com>"

ADD ./supervisord.conf /etc/supervisord.conf
ADD ./app  /app
#RUN mkdir /app
RUN groupadd app && adduser -g app app && chown -R app:app /app
WORKDIR /app

#USER app

EXPOSE 5920 5921
