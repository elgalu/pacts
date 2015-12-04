## Postgres in docker

### Env
Set all necessary environment variables we will need.
More info at http://www.postgresql.org/docs/9.4/static/libpq-envars.html

    export PGUSER=postgres
    export PGPASSWORD=xeipa2E_secret

### Pull
Pull official postgres docker image

    export PSQL_IMG="postgres:9.4.5"
    docker pull ${PSQL_IMG}

### Run
Run it

    docker run -d --name=postgres -p 5432 \
      -e POSTGRES_PASSWORD=${PGPASSWORD} \
      -e PGPASSWORD \
      -e PGUSER \
      -e PGPORT=5432 \
      ${PSQL_IMG}

### Wait
Wait for postgres to start

    script/wait_psql.sh postgres

Grab postgres IP

    export PACT_BROKER_DATABASE_HOST=`docker inspect -f '{{ .NetworkSettings.IPAddress }}' postgres`
    echo "Postgres container IP is: ${PACT_BROKER_DATABASE_HOST}"

Ensure psql is running, following command should return success (0) exit code

    docker exec -ti postgres pg_isready --host=localhost --port=5432
    #=> localhost:5432 - accepting connections

### Use
Create pacts the database

    docker exec -ti postgres psql -c 'CREATE DATABASE pact;'

### Validate
Validate the database exists

    docker exec -ti postgres psql -c '\connect pact'
    #=> You are now connected to database "pact" as user "postgres"

### Stop
Stop without loosing data

    docker stop postgres

### Restart
Simply start postgres again

    docker start postgres
    docker exec -ti postgres pg_isready --host=localhost --port=5432

### Destroy
Destory and erase all

    docker stop postgres
    docker rm postgres #DANGER: will the detroy DB!
