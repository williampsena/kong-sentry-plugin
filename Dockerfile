FROM kong:2.8.1

ADD ./sentry /usr/local/custom/kong/plugins/sentry

USER root

RUN (cd /usr/local/custom/kong/plugins/sentry && luarocks make)

USER kong