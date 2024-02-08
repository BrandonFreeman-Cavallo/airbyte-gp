FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

ENV DATA_HOME=/var/opt/mssql/data

COPY ./backups/*.bak $DATA_HOME/
RUN chown -R mssql:root $DATA_HOME && \
    chmod 0755 $DATA_HOME && \
    chmod -R 0650 $DATA_HOME/*

USER mssql
