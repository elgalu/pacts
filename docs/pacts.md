# Pact Broker via STUPS

## Requirements

* [etcd cluster](./etcd.md)
* [spilo.md](./spilo.md)

## Create a web-app senza definition
    mai
    senza init pacts.yaml

    Please select the project template
    Selected 5) webapp: HTTP app with auto scaling, ELB and DNS
    Application ID [hello-world]: pacts
    Docker image without tag/version [stups/hello-world]: docker.io/myusr/pacts
    HTTP port [8080]: 443
    HTTP health check path [/]: /diagnostic/status/heartbeat
    EC2 instance type [t2.micro]: t2.micro
    Did you need OAuth-Credentials from Mint? [y/N]: y
    Mint S3 bucket name [myorg-stups-mint-123456789012-us-east-1]:
    Please select the load balancer scheme
    1) internal: only accessible from the own VPC
    2) internet-facing: accessible from the public internet
    Please select (1-2) [1]: 2
    Security group app-pacts does not exist. Do you want Senza to create it now? [Y/n]: Y
    Security group app-pacts-lb does not exist. Do you want Senza to create it now? [Y/n]: Y

Sample output

    Checking security group app-pacts.. OK
    Checking security group app-pacts-lb.. OK
    Checking IAM role app-pacts.. OK
    Creating IAM role app-pacts.. OK
    Updating IAM role policy of app-pacts.. OK
    Generating Senza definition file pacts.yaml.. OK

Open [pacts.yaml](../pacts.yaml)

* Add `application_id: pacts` before `application_version`

* Add `health_check_timeout_seconds: 90` next to `health_check_path`

* Add `environment:` => `PACT_BROKER_DATABASE_USERNAME` and other envs vars.

* Add `root: true` due to this [annoying issue](https://github.com/zalando-stups/taupage/issues/25)

* Add Scalyr key `scalyr_account_key:` with aws kms encrypted value

### Encrypt DB user and password

#### KMS
Ref1: http://stups.readthedocs.org/en/latest/components/taupage.html#environment

Navigate to **Encryption Keys** underneath **IAM** on AWS Console and click `Create Key`
https://console.aws.amazon.com/iam/home?region=us-east-1#encryptionKeys/us-east-1

    Alias: pacts_access
    Descr: Pacts encryption for DB and other access

* Key Administrators roles: `sso-PowerUser`

* Key Usage permissions roles: `app-pacts`

Go to your terminal and encrypt the DB username using this `pacts_access` key

    pip3 install --upgrade awscli

    aws kms encrypt --key-id alias/pacts_access --plaintext "postgres" | jq .CiphertextBlob

You can include `| xclip -selection c` at the end to directly copy it to the clipboard, on Ubuntu.

#### Configure Taupage to decrypt KMS Values

Paste the encrypted CipertextBlob into the `TaupageConfig` [prefixed](http://docs.stups.io/en/latest/components/taupage.html#environment) with `aws:kms:` and do the same for the passwords. See [pacts.yaml](../pacts.yaml).

Ref2: https://github.com/zalando/kmsclient

### Register the app
Go to [Create Application](https://yourturn.stups.example.org/application/create) in your turn.

* Team ID: myusr

* Application ID: pacts

* Service url: pacts.myteam.example.org

* Fill all the other fields.

### Create version
[Create new version for Pacts Broker](https://yourturn.stups.example.org/application/detail/pacts/version/create)

* Version e.g.: `v001`

* Docker Deployment Artifact: `docker.io/myusr/pacts:0.0.1`

* Sample description: First attempt to deploy the pact broker, will probably fail due to cert issues or DB access.

### Add mint bucket
The app will show mint bucker errors as we are missing this step.

Go to [Access Control](https://yourturn.stups.example.org/application/access-control/pacts) and activate mint bucket `myorg-stups-mint-123456789012-us-east-1`

Then click [Renew Credentials](https://yourturn.stups.example.org/application/access-control/pacts)

Sample error if you skip this step:

    berry: ERROR: Access denied while trying to read "pacts/user.json" from mint S3 bucket "myorg-stups-mint-123456789012-us-east-1"

### Deploy
See [CONTRIBUTING](./CONTRIBUTING.md#deploy)

### Status
    senza wait pacts-live v001
    #=> Waiting up to 1800 more secs for stack pacts-live-v001 (CREATE_IN_PROGRESS)..
    #=> ... Stack(s) pacts-live-v001 created successfully.

    senza events pacts-live v001
    #=> ... pacts-live v001 CloudFormation::Stack pacts-staging CREATE_COMPLETE

    senza list pacts-staging
    #=> pacts-staging CREATE_COMPLETE 7m ago Pacts (Stage: staging, ImgTag: 0.0.1)

## Troubleshooting
    senza inst pacts-staging v001 -o json | jq -r .[0].private_ip
    #=> 172.31.144.171
    piu request-access -U elgalu --clip 172.31.144.171 "test"

### Logs
Logs can be found at [logStart](https://www.scalyr.com/logStart) some are:

* [/var/log/application.log](https://www.scalyr.com/events?mode=log&filter=%24logfile%3D%27%2Fvar%2Flog%2Fapplication.log%27%20%24serverHost%3D%27pacts%27)
* [/var/log/auth.log](https://www.scalyr.com/events?mode=log&filter=%24logfile%3D%27%2Fvar%2Flog%2Fauth.log%27%20%24serverHost%3D%27pacts%27)
* [/var/log/scalyr-agent-2/agent.log](https://www.scalyr.com/events?mode=log&filter=%24logfile%3D%27%2Fvar%2Flog%2Fscalyr-agent-2%2Fagent.log%27%20%24serverHost%3D%27pacts%27)
* [/var/log/syslog](https://www.scalyr.com/events?mode=log&filter=%24logfile%3D%27%2Fvar%2Flog%2Fsyslog%27%20%24serverHost%3D%27pacts%27)
