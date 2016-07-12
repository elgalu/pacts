# Clair
Docker security in containers: [clair](https://github.com/coreos/clair#clair) and [clair-sqs](https://github.com/zalando/clair-sqs)

# Pacts security
Note this requires your STUPS Pierone infrastructure to have Clair docker security installed.

## Setup
Jq is like [sed](https://en.wikipedia.org/wiki/Sed) but for JSON data

    # For OSX follow instructions at https://stedolan.github.io/jq/
    # For Linux:
    sudo apt-get -qyy install jq

Upgrade STUPS toolbox.
Ignore [pyenv](https://github.com/yyuu/pyenv) commands if you are not using it.

    pyenv shell 3.5.2
    pip3 install -U pip
    pip3 install -U stups stups-fullstop httpie-zign awscli
    pyenv rehash
    pierone cves team repo tag #test it works

Please enter the Clair URL:

    clair.stups.example.org

## Usage
Ensure you have the latest packages installed of your library and OS dependencies.

Docker build the image and push it to pierone, e.g.

    make build push STAGE=test

### Senza
Senza now notifies the severities through the `create` command but it might be better to do this before deploying the cloud formation, see *Manual* section later on.

    senza create ...
    #=> You are deploying an image that has *HIGH* severity security fixes
    #=> easily available! Please check this artifact tag in pierone and see
    #=> which software versions you should upgrade to apply those fixes.

### Manual
Define the names of team and docker image.

    team="myusr" repo="pacts"

Get latest tag then fetch vulnerabilities of HIGH severity

    pierone tags --output json --limit 1 $team $repo | jq -r '.[0].severity_fix_available' | grep NO_CVES_FOUND
    no_cves_found_grep=$?

If no vulnerabilities are found the exit code `$?` will be `4`

    if [ "$no_cves_found_grep" = "0" ]; then
      echo "No HIGH severities found, continue with deployment"
    else
      echo "Severities found or some other error" >&2
      exit 1
    fi

### Sample
Listing severities

		tag=$(pierone latest $team $repo)
    pierone cves -o json $team $repo $tag | jq -e '.[] | select(.severity=="HIGH")'

Sample output of previous `pierone cves` command

    {
      "affected_feature": "openssl:1.0.2d-0ubuntu1.4",
      "cve": "CVE-2016-2108",
      "fixing_feature": "openssl:1.0.2d-0ubuntu1.5",
      "link": "http://people.ubuntu.com/~ubuntu-security/cve/CVE-2016-2108",
      "severity": "HIGH"
    }
    {
      "affected_feature": "openssl:1.0.2d-0ubuntu1.4",
      "cve": "CVE-2016-2107",
      "fixing_feature": "openssl:1.0.2d-0ubuntu1.5",
      "link": "http://people.ubuntu.com/~ubuntu-security/cve/CVE-2016-2107",
      "severity": "HIGH"
    }

## Fix them
So how to fix the severities?
For now all we can do is upgrade the offending packages and we do this in our Dockerfile.

### Example 1
Dockerfile

    FROM ubuntu:16.04

Change to the [latest](https://registry.hub.docker.com/_/ubuntu/tags/manage/) date:

    FROM ubuntu:xenial-20160525
