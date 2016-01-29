## Prepare
    GETOK="https://token.info.example.org/access_token"
    token=$(zign token --user elgalu --url $GETOK -n pact)
    export DISPOSABLE_PSQL=true
    export OAUTH_TOKEN_INFO=https://auth.example.org/oauth2/tokeninfo?access_token=
    export MYUSER=elgalu
    REG="docker.io"

## Test
How to run the tests

    ./script/gen-scm-source.sh
    cd pact_broker && bundle install && cd ..
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
    senza console --limit 300 pacts-staging v001 | grep -iE "error|failed"
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

#### Troubleshooting

    piu ... && ssh #function pi
    cat /var/log/application.log
    cat /etc/taupage.yam
    grep "docker run" /var/log/syslog

### Open

#### New Version
open https://pacts-staging.myteam.example.org/diagnostic/status/heartbeat

#### LB
open https://pacts.myteam.example.org/diagnostic/status/heartbeat

### Approve version
Go to the [version approval page](https://yourturn.stups.example.org/application/detail/pacts/version/approve/v001)

#### Via CLI
List

    export USER=elgalu
    kio ver li pacts
    #=> Approvals: CODE_CHANGE: elgalu,
                   DEPLOY: elgalu,
                   SPECIFICATION: elgalu,
                   TEST: elgalu

Create version

    kio ver create pacts v001 docker://docker.io/myusr/pacts:0.0.1
    #=> Creating version pacts v001.. OK

Approve

    kio ver approve pacts v001
    #=> Approving SPECIFICATION of version pacts v001.. OK
    #=> Approving CODE_CHANGE of version pacts v001.. OK
    #=> Approving TEST of version pacts v001.. OK
    #=> Approving DEPLOY of version pacts v001.. OK

#### Violations
Resolve all your old violations and start fresh for next time

    export USER=elgalu
    fullstop list-violations --accounts "123456789012" --output json --since 700d -l 50
    fullstop resolve-violations --accounts "123456789012" --since 700d -l 9999 "Resolving old violations"
    #=> Resolving violation 123456789012/us-east-1 APPLICATION_VERSION_NOT_PRESENT_IN_KIO 1005936.. OK
    #=> Resolving violation 123456789012/us-east-1 SPEC_TYPE_IS_MISSING_IN_KIO 1005935.. OK
    #=> Resolving violation 123456789012/us-east-1 APPLICATION_VERSION_NOT_PRESENT_IN_KIO 1005934.. OK
    #=> Resolving violation 123456789012/us-east-1 SPEC_TYPE_IS_MISSING_IN_KIO 1005933.. OK
    #=> ...
