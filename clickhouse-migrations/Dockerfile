FROM clickhouse/clickhouse-server:latest

ENV data_home=/data/deploy

RUN mkdir -p $data_home

COPY run_script.sh $data_home/run_script.sh
RUN chmod +x $data_home/run_script.sh
CMD $data_home/run_script.sh
