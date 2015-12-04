# Pacts monitoring

Note AppDynamics doesn't support Ruby so New Relic is the only choice out there for an easy to use out of the box method level performance tracing.

#### Availability report
https://rpm.newrelic.com/accounts/123456/applications/1234567/downtime

![new-relic-availability-report](https://cloud.githubusercontent.com/assets/111569/11401761/614fcb24-9394-11e5-9949-65fe1a41172c.png)

#### Browser page load time
https://rpm.newrelic.com/accounts/123456/browser/1234567

#### Web transactions response time
https://rpm.newrelic.com/accounts/123456/applications/1234567

#### Web server dashboard
![new_relic_server_dashboard](https://cloud.githubusercontent.com/assets/111569/11401777/7708c04c-9394-11e5-8917-a9320bf2daa1.png)

#### Server monitoring
This is done Taupage side but aws:kms is not currently working with `newrelic_account_key`

#### Availability monitoring
https://rpm.newrelic.com/accounts/123456/applications/1234567/ping_targets

#### Docker
https://rpm.newrelic.com/accounts/123456/servers/1234567/virtualizations

![new-relic-docker-view](https://cloud.githubusercontent.com/assets/111569/11401712/2674e782-9394-11e5-8aa7-f93ceba08c07.png)

#### Ruby VMs
Memory and garbage collection
https://rpm.newrelic.com/accounts/123456/applications/1234567/ruby_vms

#### Database Time per Request vs. Throughput
https://rpm.newrelic.com/accounts/123456/applications/1234567/optimize/scalability_analysis#tab-metric=database

![new-relic-database-view](https://cloud.githubusercontent.com/assets/111569/11401747/55426f1c-9394-11e5-9348-413b1c2ae498.png)

#### CPU Time per Request vs. Throughput
https://rpm.newrelic.com/accounts/123456/applications/1234567/optimize/scalability_analysis#tab-metric=cpu

### KPIs

### Custom event users_kpis
    SELECT count(iam_uid) FROM users_kpi FACET iam_uid SINCE 1 MONTH AGO TIMESERIES

#### Explorer: Last month grouped by uid
https://insights.newrelic.com/accounts/123456/explorer?eventType=users_kpi&timerange=month&facet=iam_uid

#### Dashboard: Last month grouped by uid
https://insights.newrelic.com/accounts/123456/dashboards/123456

### Insights: New Relic "data app" Last week
    SELECT iam_realm, iam_uid, host, duration, error, `request.headers.host`, `request.headers.userAgent`, `request.method` FROM Transaction WHERE appName = 'pacts' AND iam_realm IS NOT NULL AND iam_uid IS NOT NULL SINCE 1 week ago

#### data-pacts
https://insights.newrelic.com/apps/accounts/123456/data-pacts

#### API key to gather KPIs
https://insights.newrelic.com/accounts/123456/manage/api_keys/query/1234

    apikey="SECRET!!!!"
    account="123456"
    select="SELECT iam_realm, iam_uid FROM Transaction WHERE appName = 'pacts' AND iam_realm IS NOT NULL AND iam_uid IS NOT NULL SINCE 1 month ago"
    url="https://insights-api.newrelic.com/v1/accounts/$account/query"
    jqq='.results[0].events | unique_by(.iam_uid)'
    curl -H "Accept: application/json" \
         -H "X-Query-Key: $apikey" \
         -G --data-urlencode "nrql=$select" \
         "$url" | jq -r "$jqq"

Note it can take from 30 seconds to minutes to have the data available.
https://stedolan.github.io/jq/manual/

    #=>
    [
      {
        "timestamp": 1448369447295,
        "iam_realm": "employees",
        "iam_uid": "elgalu"
      },
      {
        "timestamp": 1448369786667,
        "iam_realm": "services",
        "iam_uid": "stups_pacts"
      }
    ]

#### Unique employees

    select="SELECT uniques(iam_uid) FROM users_kpi FACET iam_uid WHERE iam_realm = 'employees' SINCE 1 MONTH AGO"
    jqq='.totalResult.results[0].members[]'
    curl -s -H "X-Query-Key: $apikey" -G --data-urlencode "nrql=$select" "$url" | jq -r "$jqq"
    #=> "elgalu"

#### Unique services

    select="SELECT uniques(iam_uid) FROM users_kpi FACET iam_uid WHERE iam_realm = 'services' SINCE 1 MONTH AGO"
    jqq='.totalResult.results[0].members[]'
    curl -s -H "X-Query-Key: $apikey" -G --data-urlencode "nrql=$select" "$url" | jq -r "$jqq"
    #=> "stups_pacts"

#### Other refs
This one doesn't work because it doesn't filter the results before grouping

    select="SELECT iam_realm, iam_uid FROM Transaction WHERE appName = 'pacts' AND iam_realm IS NOT NULL AND iam_uid IS NOT NULL SINCE 1 month ago"
    jqq='.results[0].events | unique_by(.iam_uid) | .[] .iam_uid'
    curl -s -H "X-Query-Key: $apikey" -G --data-urlencode "nrql=$select" "$url" | jq -r "$jqq"
    #=>
    "elgalu"
    "stups_pacts"

Only realm and user but doesn't work because it doesn't filter the results before grouping

    jqq='.results[0].events | unique_by(.iam_uid) | del(.[].timestamp) | .[] | [.iam_realm, .iam_uid] | join(",")'
    curl -s -H "X-Query-Key: $apikey" -G --data-urlencode "nrql=$select" "$url" | jq -r "$jqq"
    #=>
    employees,elgalu
    services,stups_pacts

[Alternative](http://stackoverflow.com/a/33899437/511069):

    jqq='.results[0].events | unique_by(.iam_uid) | .[] | "\(.iam_realm),\(.iam_uid)"'
    curl -s -H "X-Query-Key: $apikey" -G --data-urlencode "nrql=$select" "$url" | jq -r "$jqq"

Alternative

    jqq='.results[0].events | unique_by(.iam_uid) | .[] | [.iam_realm, .iam_uid] | @csv'
    curl -s -H "X-Query-Key: $apikey" -G --data-urlencode "nrql=$select" "$url" | jq -r "$jqq"
    #=>
    "employees","elgalu"
    "services","stups_pacts"
