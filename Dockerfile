FROM kong:3.8.0

ADD ./sentry /usr/local/custom/kong/plugins/sentry

USER root

RUN (cd /usr/local/custom/kong/plugins/sentry && luarocks make)

USER kong