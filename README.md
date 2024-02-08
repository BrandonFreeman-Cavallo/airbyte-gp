# Airbyte GP Sync

### Directions

- Add copies of GP database into the `/sql-server/backups` folder.
  - DYNAMICS16.bak
  - TWO.bak
- Start MS-SQL and Clickhouse docker containers:
  - `docker compose up -d`
- Wait for the sql server and clickhouse migrations containers to stop.
- Start Airbyte docker containers:
  - `./airbyte/run-ab-platform.sh --background`
  - The airbyte repo is a sub-module of this git repo for your convenience.
- Run `./run_script.sh -h host.docker.internal` to set up Sources, Destinations, and Connections through the API.
  - If `host.docker.internal` doesn't work, use the IP of your Hyper-V network adapter.
- Connect to the [Web interface](http://localhost:8000/).
- Serve and Enjoy!

### Reads

- [Airbyte API Docs](https://reference.airbyte.com/reference/start)

### Notes

- The standard API doesn't allow for adding data normalization through Clickhouse. We're sending an update request through the back end API.
- The current data normalization paradigm (V1) is being deprecated in early 2024, which will require destinations to move to the V2 implementation. There doesn't appear to be any documentation on how to implement Clickhouse through V2.
- The Airbyte container script (`./airbyte/run-ab-platform.sh`) has issues with `/var/run/docker.sock` through WSL. If you run it through Git Bash for Windows, it has no problems. This might be as Rancher Desktop issue, and probably needs some investigation.
- Airbyte will try to communicate with Clickhouse through SSL by default. The API documentation doesn't specify a param for SSL, but adding `"ssl":false` to the destination JSON will do the trick.
