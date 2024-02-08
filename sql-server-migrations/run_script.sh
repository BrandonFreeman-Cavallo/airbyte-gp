#!/bin/bash

export MSSQL_USER="sa"

COUNTER=1
until /opt/mssql-tools/bin/sqlcmd -S $MSSQL_HOST -U $MSSQL_USER -P $MSSQL_SA_PASSWORD -Q "SELECT 1 AS NUMBER"
do
  echo "Waiting ($COUNTER) for $MSSQL_USER:$MSSQL_SA_PASSWORD@$MSSQL_HOST to start ..."
  let COUNTER++
  sleep 5
done

/opt/mssql-tools/bin/sqlcmd -S $MSSQL_HOST -U $MSSQL_USER -P $MSSQL_SA_PASSWORD -Q "RESTORE DATABASE [DYNAMICS16] FROM DISK = 'DYNAMICS16.bak' WITH MOVE 'GPSDYNAMICS16Dat.mdf' TO '$DATA_HOME/GPSDYNAMICS16Dat.mdf', MOVE 'GPSDYNAMICS16Log.ldf' TO '$DATA_HOME/GPSDYNAMICS16Log.ldf'"
/opt/mssql-tools/bin/sqlcmd -S $MSSQL_HOST -U $MSSQL_USER -P $MSSQL_SA_PASSWORD -Q "RESTORE DATABASE [TWO] FROM DISK = 'TWO.bak' WITH MOVE 'GPSTWODat.mdf' TO '$DATA_HOME/GPSTWODat.mdf', MOVE 'GPSTWOLog.ldf' TO '$DATA_HOME/GPSTWOLog.ldf'"
