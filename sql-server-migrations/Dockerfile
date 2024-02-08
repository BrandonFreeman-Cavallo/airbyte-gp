FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

ENV DATA_HOME=/var/opt/mssql/data

COPY run_script.sh $DATA_HOME/run_script.sh
RUN chmod +x $DATA_HOME/run_script.sh
CMD $DATA_HOME/run_script.sh
