FROM ubuntu:22.04

RUN apt update &&\
    apt upgrade -y &&\
    apt install -y curl

RUN curl https://clickhouse.com/ | sh &&\
    mv clickhouse /usr/local/bin/clickhouse

ENV DATA_HOME=/data/migrations

RUN mkdir -p $DATA_HOME

COPY run_script.sh $DATA_HOME/run_script.sh
RUN chmod +x $DATA_HOME/run_script.sh
CMD $DATA_HOME/run_script.sh
