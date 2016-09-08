## Pact broker docker flow

### Build

    docker build -t pacts:latest .

### Env
Set all necessary environment variables we will need.

    export PACT_BROKER_DATABASE_HOST=`docker inspect -f '{{ .NetworkSettings.IPAddress }}' postgres`
    export PACT_BROKER_DATABASE_USERNAME=postgres
    export PACT_BROKER_DATABASE_NAME=pact
    export PGPASSWORD=xeipa2E_secret
    export PACT_BROKER_DATABASE_PASSWORD=${PGPASSWORD}
    export SKIP_HTTPS_ENFORCER=true
    export OAUTH2_ACCESS_TOKEN_URL="https://token.example.com/oauth2/tokeninfo"
    export OAUTH2_ACCESS_TOKEN_PARAMS="?access_token="
    export OAUTH2_ACCESS_TOKEN_URL_PARAMS="${OAUTH2_ACCESS_TOKEN_URL}${OAUTH2_ACCESS_TOKEN_PARAMS}"
    export TOKENINFO_URL="https://token.example.com/oauth2/tokeninfo"
    export TOKENINFO_PARAMS="?access_token="
    export TOKENINFO_URL_PARAMS="${TOKENINFO_URL}${TOKENINFO_PARAMS}"
    export APPDYNAMICS_ANALYTICS_API_ENDPOINT="https://demo.appdynamics.com"
    export APPDYNAMICS_ACCOUNT_ID="customer1_zxcvcxv3232"
    export APPDYNAMICS_API_KEY="j23423-sdasf-secret!!!"
    export EMPLOYEES_API_URL="https://api.example.com/employees"
    export BIND_TO="0.0.0.0"
    export PACT_BROKER_PORT=443
    export port=$PACT_BROKER_PORT

### Run
Run the pact broker

    docker stop -t=0 pact; docker rm pact
    docker run --rm -ti --name=pact -p $port:$port -e PACT_BROKER_DATABASE_USERNAME -e PACT_BROKER_DATABASE_PASSWORD -e PACT_BROKER_PORT -e BIND_TO -e PACT_BROKER_DATABASE_HOST -e PACT_BROKER_DATABASE_NAME -e SKIP_HTTPS_ENFORCER -e TOKENINFO_URL_PARAMS pacts:latest

Nicely formatted lines

    docker run -d --name=pact -p $port:$port \
      -e PACT_BROKER_DATABASE_USERNAME \
      -e PACT_BROKER_DATABASE_PASSWORD \
      -e PACT_BROKER_PORT \
      -e BIND_TO \
      -e PACT_BROKER_DATABASE_HOST \
      -e PACT_BROKER_DATABASE_NAME \
      -e SKIP_HTTPS_ENFORCER \
      -e TOKENINFO_URL_PARAMS \
      pacts:latest

Wait for the pact broker to finish starting

    docker exec pact wait_ready 10s

### Browser

To see it on the browser you will need a chrome extension that injects oauth2 bearer tokens into every header like https://github.com/zalando/chrome-oauth-bearer-plugin though is easier to follow the guide at https://github.com/zalando/chrome-oauth-bearer-plugin

You can still take a look and check the MissingTokenError at:

    open http://localhost:$port

### Stop
Stop without loosing data

    docker stop pact
    docker rm pact

### Restart
Just run a new `pact` container, no need to reuse the old one as the persistance is only in postgres side.

    #docker run -d --name=pact ..... (see above)

### Destroy
Stop and destory the disposable container

    docker stop pact
    docker rm pact
