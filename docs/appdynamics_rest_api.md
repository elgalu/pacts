## AppDynamics REST API
Notes on how to use the AppDynamics REST API.

### Setup

    export APPDYNAMICS_TEAM_API_ACCN="ourAPIaccount"
    export APPDYNAMICS_TEAM_API_USER="ourAPIuser"
    export APPDYNAMICS_TEAM_API_PASS="better.ask.to.your.colleagues"
    export APPDYNAMICS_API_ENDPOINT="http://demo.appdynamics.com"
    export APAUTH="${APPDYNAMICS_TEAM_API_USER}@${APPDYNAMICS_TEAM_API_ACCN}:${APPDYNAMICS_TEAM_API_PASS}"

### Get applications

    API_PATH="controller/rest/applications"
    curl --user ${APAUTH} "${APPDYNAMICS_API_ENDPOINT}/${API_PATH}"


### Get events
Get APP_SERVER_RESTART or APPLICATION_ERROR events

    API_PATH="controller/rest/applications/TestInfrastructure/events?output=JSON"
    API_PARA=""
    API_PARA="${API_PARA}&time-range-type=BEFORE_NOW"
    API_PARA="${API_PARA}&duration-in-mins=360"
    API_PARA="${API_PARA}&severities=INFO,WARN,ERROR"
    API_PARA="${API_PARA}&event-types=APP_SERVER_RESTART,APPLICATION_ERROR"
    curl --user ${APAUTH} "${APPDYNAMICS_API_ENDPOINT}/${API_PATH}${API_PARA}"

See sample output at [appdynamics_events.json](https://gist.github.com/elgalu/62152e253406307a09b4ca51f2581ef9)

### Get CUSTOM events

    API_PATH="controller/rest/applications/TestInfrastructure/events?output=JSON"
    API_PARA=""
    API_PARA="${API_PARA}&time-range-type=BEFORE_NOW"
    API_PARA="${API_PARA}&duration-in-mins=360"
    API_PARA="${API_PARA}&severities=INFO,WARN,ERROR"
    API_PARA="${API_PARA}&event-types=CUSTOM"
    curl --user ${APAUTH} "${APPDYNAMICS_API_ENDPOINT}/${API_PATH}${API_PARA}"

### POST CUSTOM event
Via JSON. WIP...

    API_PATH="controller/rest/applications/TestInfrastructure/events"
    API_DATA=""
    API_DATA="${API_DATA}{"
    API_DATA="${API_DATA}\"eventtype\":\"CUSTOM\""
    API_DATA="${API_DATA},\"summary\":\"usage\""
    API_DATA="${API_DATA},\"customeventtype\":\"kpi\""
    API_DATA="${API_DATA},\"propertynames\":\"iam_uid\""
    API_DATA="${API_DATA},\"propertynames\":\"iam_realm\""
    API_DATA="${API_DATA},\"propertynames\":\"team\""
    API_DATA="${API_DATA},\"propertyvalues\":\"leo\""
    API_DATA="${API_DATA},\"propertyvalues\":\"employees\""
    API_DATA="${API_DATA},\"propertyvalues\":\"tip\""
    API_DATA="${API_DATA},\"severity\":\"INFO\""
    API_DATA="${API_DATA}}"
    curl --user ${APAUTH} -X POST --data "${API_DATA}" "${APPDYNAMICS_API_ENDPOINT}/${API_PATH}"

Via url params ... WIP ...

    API_PATH="controller/rest/applications/TestInfrastructure/events"
    API_PARA="eventtype=CUSTOM"
    API_PARA="${API_PARA}&customeventtype=kpi"
    API_PARA="${API_PARA}&summary=usage"
    API_PARA="${API_PARA}&propertynames=iam_uid&propertynames=iam_realm&propertynames=team"
    API_PARA="${API_PARA}&propertyvalues=leo&propertyvalues=employees&propertyvalues=tip"
    API_PARA="${API_PARA}&severity=INFO"
    curl --user ${APAUTH} -X POST --data "${API_PARA}" "${APPDYNAMICS_API_ENDPOINT}/${API_PATH}"
    curl --user ${APAUTH} -X POST "${APPDYNAMICS_API_ENDPOINT}/${API_PATH}${API_PARA}"


Will get `The server encountered an internal error () that prevented it from fulfilling this request.` error 500 if the user has only read access to the API.
