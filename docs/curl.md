## Curling
Examples.

### Requisites
Avoid using `curl --insecure` else your oauth2 tokens may be intercepted by a MITM impostor.
To do so you may need [specific certs](https://github.com/zalando/docker-ubuntu/blob/master/Dockerfile#L10) if dealing with self-signed certificates.

### Localhost

    export SHOST=http://localhost:443

### Staging

    export SHOST=https://pacts.myteam-test.example.org

### Production

    export SHOST=https://pacts.myteam.example.org

Heartbeat should always return 200 OK, without the need of security

    curl $SHOST/diagnostic/status/heartbeat
    #=> {"ok":true,"_links":{"self":{"href":"$SHOST/diagno...

Trigger access denied due to too many failed requests per second (throttle)

    curl $SHOST; curl $SHOST; curl $SHOST; curl $SHOST
    #=> {"code":429,"message":"AccessDenied","reason":"blocked","error":"request_blocked","error_description":"RequestBlocked"}

Bad token

    curl -H "Authorization: Bearer ASDFASDF" $SHOST
    #=> {"code":401,"message":"InvalidTokenError","reason":"unauthorized","error":"invalid_token","error_description":"InvalidTokenError"}

### User token
Get valid token. Note you need python3 and `pip3 install httpie-zign`. You also need to replace `elgalu` with your token service user id, most likely is the same as your machine `$USER`.
This will be a user token to test from your machine, if you need to do this from another service machine like an AWS Jenkins one see "Service token" below.

    GETOK="https://token.info.example.org/access_token"
    token=$(zign token --user elgalu --url $GETOK -n pact)

### Service token
From a service instance like an AWS Jenkins.

#### Requirements
    RUN apt-get update -qq && apt-get install -qqy jq curl
    RUN curl -L http://cpanmin.us | perl - App::cpanminus
    RUN cpanm URI::Escape

#### Get token
Note you need the [get_token.sh](../container/usr/bin/get_token.sh) script.
Ensure it has the correct token endpoint before using it, e.g. `https://auth.example.org/oauth2/access_token`

    export SHOST=https://pacts.myteam-test.example.org
    token=$(get_token.sh)

## Use
Use valid token

    curl -H "Authorization: Bearer $token" $SHOST
    #=> {"_links":{"self":{"href":"$SHOST",".....

Get the HTML output instead of json

    curl -H "Authorization: Bearer $token" \
         -H "Accept:text/html" \
         "$SHOST/ui/relationships"

### Write

    PACT='{"provider": {"name": "prov2"}, "consumer": {"name": "cons2"} }'
    curl -H "Authorization: Bearer $token" \
            -H 'Content-Type: application/json' -X PUT -d"${PACT}" \
            "$SHOST/pacts/provider/prov2/consumer/cons2/version/1.0.0"

Sample output

    {"provider":{"name":"prov2"},"consumer":{"name":"cons2"},"createdAt":"2015-11-04T18:03:43+00:00","_links":{"self":{"title":"Pact","name":"Pact between cons2 (v1.0.0) and prov2","href":"https://pacts.myteam-test.example.org/pacts/provider/prov2/consumer/cons2/version/1.0.0"},"pb:consumer":{"title":"Consumer","name":"cons2","href":"https://pacts.myteam-test.example.org/pacticipants/cons2"},"pb:provider":{"title":"Provider","name":"prov2","href":"https://pacts.myteam-test.example.org/pacticipants/prov2"},"pb:latest-pact-version":{"title":"Pact","name":"Latest version of this pact","href":"https://pacts.myteam-test.example.org/pacts/provider/prov2/consumer/cons2/latest"},"pb:previous-distinct":{"title":"Pact","name":"Previous distinct version of this pact","href":"https://pacts.myteam-test.example.org/pacts/provider/prov2/consumer/cons2/version/1.0.0/previous-distinct"},"pb:diff-previous-distinct":{"title":"Diff","name":"Diff with previous distinct version of this pact","href":"https://pacts.myteam-test.example.org/pacts/provider/prov2/consumer/cons2/version/1.0.0/diff/previous-distinct"},"pb:pact-webhooks":{"title":"Webhooks for the pact between cons2 and prov2","href":"https://pacts.myteam-test.example.org/webhooks/provider/prov2/consumer/cons2"},"pb:tag-prod-version":{"title":"Tag this version as 'production'","href":"https://pacts.myteam-test.example.org/pacticipants/cons2/versions/1.0.0/tags/prod"},"pb:tag-version":{"title":"Tag version","href":"https://pacts.myteam-test.example.org/pacticipants/cons2/versions/1.0.0/tags/{tag}"},"curies":[{"name":"pb","href":"https://pacts.myteam-test.example.org/doc/{rel}","templated":true}]}}

### Read
Reading JSON

    curl -H "Authorization: Bearer $token" -s \
      "$SHOST/pacts/provider/prov2/consumer/cons2/latest" | jq .provider.name
    #=> "prov2"

Reading HTML

    curl -H "Authorization: Bearer $token" -s \
            -H "Accept:text/html" \
            "$SHOST/pacts/provider/prov2/consumer/cons2/latest"

### Delete
Destroy pacts

    curl -H "Authorization: Bearer $token" \
            -H 'Content-Type: application/json' -X DELETE \
            "$SHOST/pacts/provider/prov2/consumer/cons2/version/1.0.0"

## Version example
    GETOK="https://token.info.example.org/access_token"
    SHOST=https://pacts.myteam-test.example.org
    token=$(zign token --user elgalu --url $GETOK -n pact)
    curl -H "Authorization: Bearer $token" $SHOST

## Performance

Noticed that it makes no difference to use an instance bigger than `t2.nano` with a small amount of expected traffic.

### Benchmark
Simple performance test

    ab -n 100 -c 10 -k -H "Authorization: Bearer $token" $SHOST/

## Impersonate
Ensure that the [impersonate](./script/impersonate) script has the correct `--token-endpoint` before using it.

    ./script/impersonate pacts

    #=> Trying to detect your stups-mint bucket... [myorg-stups-mint-123456789012-us-east-2]
    #=> Fetching credentials for [pacts] from [myorg-stups-mint-123456789012-us-east-2]... OK
    #=> Requesting token for [uid] from [https://auth.example.org/oauth2/access_token?realm=/services]... OK
    #=> {"scope":"uid","expires_in":3599,"token_type":"Bearer","access_token":"XXXX-****-4469-8243-0448c1cXXXXX"}

Note in this case we use the application_id `pacts` and not a particular stack name.
