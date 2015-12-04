## Prepare
    GETOK="https://token.info.example.org/access_token"
    token=$(zign token --user elgalu --url $GETOK -n pact)
    ./script/gen-scm-source.sh

## Test
How to run the tests

    export DISPOSABLE_PSQL=true
    export OAUTH_TOKEN_INFO=https://auth.example.org/oauth2/tokeninfo?access_token=
    export MYUSER=elgalu
    script/test.sh

## Commit
Git add and commit your changes

    git add .
    git commit -m "message"

## Build
How to build the image

    ./script/gen-scm-source.sh
    docker build -t pacts:latest .

## Git tag and push

    TAG="0.0.1" && git tag $TAG
    git push && git push --tags

## Env
Define your docker registry

    REG="docker.io"

## Push
Login to the docker repo and push

    pierone login --url $REG --user elgalu
    docker tag pacts:latest $REG/myusr/pacts:$TAG
    docker push $REG/myusr/pacts:$TAG

### Deploy
    vers="v001"

#### Staging
Note: add `--disable-rollback` to troubleshoot when the stacks fails to create.

    senza create pacts.yaml v001 Stage=staging ImgTag=$TAG
    senza wait pacts-staging v001
    senza console --limit 300 pacts-staging v001 | grep -iE "error|warn|failed"
    senza traffic pacts-staging v001 100

#### Live
Note: add `--disable-rollback` to troubleshoot

    senza create pacts.yaml v001 Stage=live ImgTag=$TAG
    senza wait pacts-live v001 #=> Stack(s) pacts-live-vvvvv created successfully.
    senza console --limit 300 pacts-live v001 | grep -iE "error|warn|failed"

##### Traffic
Redirect all traffic to the latest

    senza traffic pacts-live v001 100
    #=> Setting weights for ['pacts-live.myteam.example.org.'].. OK

##### Delete old stacks
TODO: How to wait for the traffic to be fully switched before deletion?

    senza delete pacts-live v000
    senza wait -d pacts-live v000

##### CNAME Alias
Only the first time make an alias to the live DNS using [cli53](https://github.com/barnybug/cli53)

    cli53 rrcreate myteam.example.org "pacts CNAME pacts-live.myteam.example.org."

### Open

#### New Version
open https://pacts-staging.myteam.example.org/diagnostic/status/heartbeat

#### LB
open https://pacts.myteam.example.org/diagnostic/status/heartbeat

### Approve version
Go to the [version approval page](https://yourturn.stups.example.org/application/detail/pacts/version/approve/v001)
