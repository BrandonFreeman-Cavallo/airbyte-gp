#!/bin/bash

echo "running from $DATA_HOME/sql to $CLICKHOUSE_HOST"

until clickhouse client --host "$CLICKHOUSE_HOST"\
  --port "$CLICKHOUSE_PORT"\
  --user "$CLICKHOUSE_USER"\
  --password "$CLICKHOUSE_PASSWORD"\
  --query "SELECT 1 AS NUMBER"
do
  echo "Waiting for $CLICKHOUSE_USER@$CLICKHOUSE_HOST:$CLICKHOUSE_PORT to start ..."
  sleep 5
done

# Run scripts

cd "$DATA_HOME/sql"

# touch history.log

for FILE in *.sql; do

#   HASH=$(sha256sum $FILE | cut -f 1 -d " ")

#   if grep -Fxq "$HASH" history.log; then
#     echo "$FILE ($HASH) has already been executed on $CLICKHOUSE_HOST:$CLICKHOUSE_PORT"
#     continue
#   fi

  echo "Running $FILE ($HASH) on $CLICKHOUSE_HOST:$CLICKHOUSE_PORT ..."

  clickhouse client --host "$CLICKHOUSE_HOST"\
    --port "$CLICKHOUSE_PORT"\
    --user "$CLICKHOUSE_USER"\
    --password "$CLICKHOUSE_PASSWORD"\
  --queries-file "$FILE"

  if [ $? -eq 0 ]
  then
    # echo $HASH >> history.log
    echo "Successfully executed $FILE on $CLICKHOUSE_HOST:$CLICKHOUSE_PORT"
  else
    echo "Execution FAILED for $FILE on $CLICKHOUSE_HOST:$CLICKHOUSE_PORT"
  fi
done

echo "DONE building $CLICKHOUSE_HOST:$CLICKHOUSE_PORT!"
