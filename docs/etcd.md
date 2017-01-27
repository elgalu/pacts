# Your etcd cluster

## Requirements

* AWS account

* Python 3.5.0

### STUPS
    pip3 install --upgrade pip
    pip3 install --upgrade stups httpie-zign
    stups configure stups.example.org

### zaws
Note `myteam` is our account name:

    zaws login myteam PowerUser
    zaws set-default myteam PowerUser

### Region
    echo -e "[default]\nregion = us-east-2\n" > $HOME/.aws/config

## Create the etcd cluster
Docs: http://spilo.readthedocs.org/en/latest/user-guide/deploy_etcd/
> Deploying etcd should be a once in a VPC-lifetime thing

### Template
First download then customize the [etcd.yaml](../etcd.yaml)

    wget https://raw.githubusercontent.com/zalando/stups-etcd-cluster/master/etcd-cluster.yaml
    vim etcd.yaml

* Adjust Minimum and Maximum

* Hard-code HOSTED_ZONE (HostedZone) as it won't change on every formation

* Grab the [latest docker tag](https://registry.opensource.zalan.do/v1/repositories/acid/etcd-cluster/tags) and hard-code it into TaupageConfig => source as we can keep it in source control, no need to pass it via command line arguments, e.g. `etcd-cluster:2.2.2-p7`

### Deploy
Find `SCALYR_KEY` within [write logs](https://www.scalyr.com/keys)

    SCALYR_KEY="secret!!!"
    VERSION=etcd
    senza create etcd.yaml $VERSION ScalyrAccountKey=$SCALYR_KEY
    senza wait etcd.yaml

* Stack name and stack instance will be `etcd-cluster-etcd` see [why here](https://github.com/zalando/stups-etcd-cluster#step-2-confirm-successful-cluster-creation)

* DNS A record 'etcd-server.etcd.'

* DNS SRV peer port `2380` at '_etcd-server._tcp.etcd.'

* DNS SRV client port `2379` at '_etcd._tcp.etcd.'

#### Status
    senza events etcd.yaml
    #=> ... etcd-cluster etcd CloudFormation::Stack CREATE_COMPLETE

    senza list etcd.yaml
    #=> etcd-cluster etcd CREATE_COMPLETE 22m ago

### Logs
Logs can be found at [logStart](https://www.scalyr.com/logStart) some are:

* [/var/log/application.log](https://www.scalyr.com/events?mode=log&filter=$logfile%3D%27%2Fvar%2Flog%2Fapplication.log%27%20$serverHost%3D%27etcd-cluster%27)
* [/var/log/auth.log](https://www.scalyr.com/events?mode=log&filter=$logfile%3D%27%2Fvar%2Flog%2Fauth.log%27%20$serverHost%3D%27etcd-cluster%27)
* [/var/log/scalyr-agent-2/agent.log](https://www.scalyr.com/events?mode=log&filter=$logfile%3D%27%2Fvar%2Flog%2Fscalyr-agent-2%2Fagent.log%27%20$serverHost%3D%27etcd-cluster%27)
* [/var/log/syslog](https://www.scalyr.com/events?mode=log&filter=$logfile%3D%27%2Fvar%2Flog%2Fsyslog%27%20$serverHost%3D%27etcd-cluster%27)

## Upgrade taupage AMI
http://docs.stups.io/en/latest/user-guide/maintenance.html

    senza patch etcd-cluster etcd --image=latest
    #=> Patching Auto Scaling Group etcd-cluster-etcd-AppServer-4PO46P..... OK

- Run 5 nodes (to decrease risk of losing quorum)
- Upgrade to a newer Docker image
- Do things only 1 node at a time
- Only continue with the next step if all members of the etcd cluster are healthy

Now terminate the instances 1 at a time, you can do this through the AWS console.

Note this doesn't work for stateful apps like etcd so just kept here as reference:

    senza respawn-instances etcd-cluster etcd
    #=> 3/3 instances need to be updated in etcd-cluster-etcd-AppServer-4PO46P....
    #=> Suspending scaling processes for etcd-cluster-etcd-AppServer-4PO46P...... OK
    #=> Scaling to 4 instances.. . . . . . . . . . . . . . . . . . . . . . . . OK
    #=> Terminating old instance i-65ed6..... OK
    #=> Scaling to 4 instances.. . . . . . . . . . . . . OK
    #=> Terminating old instance i-8ce5b..... OK
    #=> Scaling to 4 instances.. . . . . . . . . . . . . . . . . . OK
    #=> Terminating old instance i-e6ef0..... OK
    #=> Resetting Auto Scaling Group to original capacity (3-3-5).. OK
    #=> Resuming scaling processes for etcd-cluster-etcd-AppServer-4PO46P...... OK
