FROM kong:3.9.0

COPY sentry-0.0.1-1.rockspec /usr/local/custom/
COPY ./kong/plugins /usr/local/custom/kong/plugins

USER root

RUN (cd /usr/local/custom/ && luarocks make sentry-0.0.1-1.rockspec)

USER kong