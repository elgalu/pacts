# Your PostgreSQL via Spilo

## Requirements

* [etcd cluster](./etcd.md)

## Create spilo senza definition
    mai
    senza init spilo.yaml

Select `postgresapp: HA Postgres app` project [template](https://github.com/zalando-stups/senza/blob/master/senza/templates/postgresapp.py)

* Set docker image: y
* Docker image: registry.opensource.zalan.do/acid/spilo-9.4:0.5-p1 (default)
* WAL S3 to use: Change to unused one, e.g. `myorg-myteam-us-east-1-spilo-pacts`
* EC2 instance type: t2.nano
* domain: [2]: 
* ETCD Discovery Domain: etcd.
* DB size: 10GB (default)
* DB volume type: gp2 (default) [differences](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSVolumeTypes.html)
* Filesystem: ext4 (default)
* Filesystem mount options: noatime,nodiratime,nobarrier (default)
* Scalyr account: get it at [write logs](https://www.scalyr.com/keys)

Sample output

    Checking security group app-spilo.. OK
    Checking S3 bucket myorg-myteam-us-east-1-spilo-pacts.. OK
    Creating S3 bucket myorg-myteam-us-east-1-spilo-pacts... OK
    Generating Senza definition file spilo.yaml.. OK

Note latest spilo docker image can be found [here](https://registry.opensource.zalan.do/v1/repositories/acid/spilo-9.4/tags) and tag `latest` should be a pointer to the most recent.

Open [spilo.yaml](../spilo.yaml)

* Fix hard-coded Scalyr key with `scalyr_account_key: '{{Arguments.ScalyrAccountKey}}'`

* Add `Parameters:` => `- ScalyrAccountKey:` => `Description: scalyr account key` to `SenzaInfo:`

* In `PostgresRoute53Record:` add `-master` to the dns name

### Deploy
    SCALYR_KEY="secret!!!"
    senza create spilo.yaml db ScalyrAccountKey=$SCALYR_KEY

#### Status
    senza events spilo.yaml
    #=> ... spilo db CloudFormation::Stack spilo-db CREATE_COMPLETE

    senza list spilo.yaml
    #=> spilo db CREATE_COMPLETE  7m ago Spilo Pacts

### Logs
Logs can be found at [logStart](https://www.scalyr.com/logStart) some are:

* [/var/log/application.log](https://www.scalyr.com/events?mode=log&filter=$logfile%3D%27%2Fvar%2Flog%2Fapplication.log%27%20$serverHost%3D%27spilo%27)
* [/var/log/auth.log](https://www.scalyr.com/events?mode=log&filter=$logfile%3D%27%2Fvar%2Flog%2Fauth.log%27%20$serverHost%3D%27spilo%27)
* [/var/log/scalyr-agent-2/agent.log](https://www.scalyr.com/events?mode=log&filter=$logfile%3D%27%2Fvar%2Flog%2Fscalyr-agent-2%2Fagent.log%27%20$serverHost%3D%27spilo%27)
* [/var/log/syslog](https://www.scalyr.com/events?mode=log&filter=$logfile%3D%27%2Fvar%2Flog%2Fsyslog%27%20$serverHost%3D%27spilo%27)



### LB Status: OUT_OF_SERVICE
Sample `senza instances` output of a healthy cluster:

    senza instances spilo.yaml
    #=> Stack|Ver│Resource |Instance  |Pub│Private IP    │State  │LB Status     │Launched
        Name │   │ID       │ID        │IP │              │       │              │
    #=> spilo│db │AppServer│i-2ae10b93│   │172.31.169.164│RUNNING│OUT_OF_SERVICE│1h ago
    #=> spilo│db │AppServer│i-69e0b7d0│   │172.31.130.175│RUNNING│IN_SERVICE    │1h ago
    #=> spilo│db │AppServer│i-a0f77118│   │172.31.152.66 │RUNNING│OUT_OF_SERVICE│1h ago

> *LB Status: OUT_OF_SERVICE* in this case means that read-write traffic will not be targeted to that node via the load balancer (the balancing concept is abused here to divert traffic to the master). With newer versions of senza and splio there's also separate load balancer for read-only connections. this one is the opposite of the former and will indeed balance traffic among available replica instances. - @a1exsh

### Connect
To connect to Postgres first open tunnel to Postgres:

    export MYUSER=elgalu
    export JUMPH="${MYUSER}@odd-us-east-1."
    export SOPTS="-o StrictHostKeyChecking=no"
    export TUNOPTS="-v -N $SOPTS"
    export JUMPOPTS="-tA $SOPTS"
    export INST="db-master."
    ssh $JUMPOPTS -vN -L localhost:6666:$INST:5432 $JUMPH

Now connect from your machine through the tunnel. If you get error `administratively prohibited: open failed` is probably because you made a mistake with the DNS name, check `db-master.` matches what will be build in `PostgresRoute53Record` => `Properties` => `Name`.

    export PGPASSWORD=zalando
    psql -h localhost -p 6666 -U postgres -d postgres

The new spilo image has 2 database default users/passwords: `admin/admin` and `postgres/zalando` and they can be found [in the source code](https://github.com/zalando/spilo/blob/master/postgres-appliance/postgres_ha.sh#L76).

    export PGPASSWORD=admin
    psql -h localhost -p 6666 -U admin -d postgres

#### Change default passwords
Right now is not so simple, check https://github.com/zalando/spilo/issues/31 for updates.

#### Create DB
    export PGPASSWORD=zalando
    psql -h localhost -p 6666 -U postgres -c 'CREATE DATABASE pact;'

## Troubleshoot
    senza instances spilo.yaml
    piu request-access -U elgalu --clip 172.31.152.66 "check errors"
    #paste ssh copied command
    cat /var/log/application.log

### Restart Scalyr
    sudo /etc/init.d/scalyr-agent-2 restart

Restart Scalyr on all your AWS account instances deployed with senza
Just change `odd-us-east-1.` and `elgalu` depending on your team and user name.

    for ip in $(senza inst -o tsv | awk -F'\t' '{print $6}'); do
      [ "$ip" == "private_ip" ] && continue #skip header
      piu request-access -U elgalu --clip $ip "Restart Scalyr"
      ssh -tA elgalu@odd-us-east-1. ssh -o StrictHostKeyChecking=no elgalu@$ip sudo /etc/init.d/scalyr-agent-2 restart
    done



## Upgrade taupage AMI
http://docs.stups.io/en/latest/user-guide/maintenance.html

    senza patch spilo db --image=latest
    #=> Patching Auto Scaling Group spilo-db-AppServer-7WZFSMNZ..... OK

Now terminate the instances 1 at a time starting with the slaves and finally the master, you can do this through the AWS console.
