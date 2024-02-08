#!/bin/bash

while getopts h: flag
do
    case "${flag}" in
        h) DOCKER_HOST=${OPTARG};;
    esac
done

AIRBYTE_HOST='http://localhost:33014'
AIRBYTE_UI_HOST='http://localhost:8000'
AIRBYTE_VERSION='v1'
AIRBYTE_URL="$AIRBYTE_HOST/$AIRBYTE_VERSION"
AIRBYTE_USER='airbyte'
AIRBYTE_PASS='password'
AIRBYTE_CREDS="$AIRBYTE_USER:$AIRBYTE_PASS"

GP_MSSQL_HOST=$DOCKER_HOST
GP_CLICKHOUSE_HOST=$DOCKER_HOST

SOURCE_NAME="GP-mssql"
DESTINATION_NAME="GP-clickhouse"
CONNECTION_NAME="GP-sync"

function get_api_status(){
    curl --request GET \
         --silent \
         --head \
         --user "$AIRBYTE_CREDS" \
         --url $AIRBYTE_HOST/health | awk '/^HTTP/{print $2}'
}

while [[ "$(get_api_status)" != "200" ]]
do
  echo "Waiting API to start ..."
  sleep 5
done

echo "Airbyte API Started ..."

WORKSPACE_ID=$(curl --request GET \
     --user "$AIRBYTE_CREDS" \
     --silent \
     --url "$AIRBYTE_URL/workspaces?includeDeleted=false&limit=20&offset=0" \
     --header 'accept: application/json' | grep -o '"workspaceId":"[^"]*' | grep -o '[^"]*$')

echo "Using workspace: $WORKSPACE_ID"

FOUND_SOURCE=$(curl --request GET \
     --user "$AIRBYTE_CREDS" \
     --silent \
     --url "$AIRBYTE_URL/sources?includeDeleted=false&limit=20&offset=0" \
     --header 'accept: application/json' | grep -o '"name":"'$SOURCE_NAME | head -1 | grep -o '[^"]*$')


if [[ "$FOUND_SOURCE" != "$SOURCE_NAME" ]]; then
    echo "Creating source: $SOURCE_NAME"

    curl --request POST \
        --user "$AIRBYTE_CREDS" \
        --silent \
        --url $AIRBYTE_URL/sources \
        --header 'accept: application/json' \
        --header 'content-type: application/json' \
        --data '
    {
    "configuration": {
        "sourceType": "mssql",
        "ssl_method": {
        "ssl_method": "encrypted_trust_server_certificate"
        },
        "replication_method": {
        "method": "STANDARD"
        },
        "tunnel_method": {
        "tunnel_method": "NO_TUNNEL"
        },
        "host": "'"$GP_MSSQL_HOST"'",
        "port": 1433,
        "database": "TWO",
        "username": "sa",
        "password": "SuperSecret123"
    },
    "workspaceId": "'"$WORKSPACE_ID"'",
    "name": "'"$SOURCE_NAME"'"
    }
    '

else
    echo "Source already exists: $SOURCE_NAME"
fi  

FOUND_DESTINATION=$(curl --request GET \
     --user "$AIRBYTE_CREDS" \
     --silent \
     --url "$AIRBYTE_URL/destinations?includeDeleted=false&limit=20&offset=0" \
     --header 'accept: application/json' | grep -o "\"name\":\"$DESTINATION_NAME" | head -1 | grep -o '[^"]*$')

if [[ "$FOUND_DESTINATION" != "$DESTINATION_NAME" ]]; then
    echo "Creating destination: $DESTINATION_NAME"

    curl --request POST \
        --user "$AIRBYTE_CREDS" \
        --silent \
        --url $AIRBYTE_URL/destinations \
        --header 'accept: application/json' \
        --header 'content-type: application/json' \
        --data '
    {
    "configuration": {
        "destinationType": "clickhouse",
        "port": 8123,
        "ssl":false,
        "tunnel_method": {
        "tunnel_method": "NO_TUNNEL"
        },
        "host": "'"$GP_CLICKHOUSE_HOST"'",
        "database": "analytics",
        "username": "default",
        "password": "default"
    },
    "name": "'"$DESTINATION_NAME"'",
    "workspaceId": "'"$WORKSPACE_ID"'"
    }
    '
else
    echo "Destination already exists: $DESTINATION_NAME"
fi 

CONNECTION_ID=$(curl --request GET \
     --user "$AIRBYTE_CREDS" \
     --silent \
     --url "$AIRBYTE_URL/connections?includeDeleted=false&limit=20&offset=0" \
     --header 'accept: application/json' | grep -o '"connectionId":"[^"]*","name":"'$CONNECTION_NAME | head -1 \
        | grep -o '"connectionId":"[^"]*' | grep -o '[^"]*$')

if [[ "$CONNECTION_ID" == "" ]]; then
    echo "Creating connection: $CONNECTION_NAME"

    SOURCE_ID=$(curl --request GET \
     --user "$AIRBYTE_CREDS" \
     --silent \
     --url "$AIRBYTE_URL/sources?includeDeleted=false&limit=20&offset=0" \
     --header 'accept: application/json' | grep -o '"sourceId":"[^"]*","name":"'$SOURCE_NAME | head -1 \
        | grep -o '"sourceId":"[^"]*' | grep -o '[^"]*$')

    echo "Source ID: $SOURCE_ID"

    DESTINATION_ID=$(curl --request GET \
        --user "$AIRBYTE_CREDS" \
        --silent \
        --url "$AIRBYTE_URL/destinations?includeDeleted=false&limit=20&offset=0" \
        --header 'accept: application/json' | grep -o '"destinationId":"[^"]*","name":"'$DESTINATION_NAME | head -1 \
            | grep -o '"destinationId":"[^"]*' | grep -o '[^"]*$')

    echo "Destination ID: $DESTINATION_ID"

    CONNECTION_ID=$(curl --request POST \
        --user "$AIRBYTE_CREDS" \
        --silent \
        --url "$AIRBYTE_URL/connections" \
        --header 'accept: application/json' \
        --header 'content-type: application/json' \
        --data '
    {
        "name": "'"$CONNECTION_NAME"'",
        "sourceId": "'"$SOURCE_ID"'",
        "destinationId": "'"$DESTINATION_ID"'",
        "workspaceId": "'"$WORKSPACE_ID"'",
        "status": "active",
        "schedule":
        {
            "scheduleType": "cron",
            "cronExpression": "0 0 * * * ? UTC"
        },
        "dataResidency": "auto",
        "nonBreakingSchemaUpdatesBehavior": "propagate_columns",
        "namespaceDefinition": "destination",
        "namespaceFormat": null,
        "configurations":
        {
            "streams":
            [
                {"name":"IV00101","syncMode":"incremental_deduped_history","cursorField":["DEX_ROW_TS"]},
                {"name":"IV40201","syncMode":"incremental_deduped_history","cursorField":["DEX_ROW_TS"]},
                {"name":"RM00101","syncMode":"incremental_deduped_history","cursorField":["DEX_ROW_TS"]},
                {"name":"RM00201","syncMode":"full_refresh_overwrite"},
                {"name":"RM00301","syncMode":"incremental_deduped_history","cursorField":["DEX_ROW_TS"]},
                {"name":"SOP10100","syncMode":"incremental_deduped_history","cursorField":["DEX_ROW_TS"]},
                {"name":"SOP10200","syncMode":"incremental_deduped_history","cursorField":["DEX_ROW_TS"]},
                {"name":"SOP30200","syncMode":"incremental_deduped_history","cursorField":["DEX_ROW_TS"]},
                {"name":"SOP30300","syncMode":"incremental_deduped_history","cursorField":["DEX_ROW_TS"]},
                {"name":"SOP40200","syncMode":"full_refresh_overwrite"},
                {"name":"SY01200","syncMode":"incremental_deduped_history","cursorField":["DEX_ROW_TS"]}
            ]
        }
    }
    '| grep -o '"connectionId":"[^"]*","name":"'$CONNECTION_NAME | head -1 \
        | grep -o '"connectionId":"[^"]*' | grep -o '[^"]*$')

    echo "Created Connection: $CONNECTION_ID"

    NORMALIZATION_RESULT=$(curl --request POST \
        --user "$AIRBYTE_CREDS" \
        --silent \
        --url "$AIRBYTE_UI_HOST/api/v1/web_backend/connections/update" \
        --header 'accept: application/json' \
        --header 'content-type: application/json' \
        --data '
        {
            "connectionId": "'"$CONNECTION_ID"'",
            "operations": [
                {
                    "name": "Normalization",
                    "workspaceId": "'"$WORKSPACE_ID"'",
                    "operatorConfiguration": {
                        "operatorType": "normalization",
                        "normalization": {
                        "option": "basic"
                        }
                    }
                }
            ]
        }
        ')

else
    echo "Connection already exists: $CONNECTION_NAME"
fi 

echo "Done"
