#!/bin/bash

COMMAND=$1
PROJECT_ID=${2:-unknown}
ALLURE_RESULTS_DIRECTORY=${3:-allure-results}
ALLURE_SERVER=$ALLURE_SERVER_URL
SECURITY_USER=$ALLURE_USER
SECURITY_PASS=$ALLURE_PASS

# Escape unsupported characters in PROJECT_ID
PROJECT_ID="${PROJECT_ID//[^a-zA-Z0-9]/-}"

# set -o xtrace
print_usage() {
    echo "Available commands: upload, delete_project, clean_results"
    echo "Usage:"
    echo "  $0 upload [project_id] [allure-results-folder]"
    echo "  $0 delete_project [project_id]"
    echo "  $0 clean_results [project_id]"
}

login() {
    echo "------------------LOGIN-----------------"

    curl -X POST "$ALLURE_SERVER/allure-api/login" \
        -H 'Content-Type: application/json' \
        -d "{\"username\":\"$SECURITY_USER\",\"password\":\"$SECURITY_PASS\"}" \
        -c cookiesFile -k

    echo "------------------EXTRACTING-CSRF-ACCESS-TOKEN------------------"
    CRSF_ACCESS_TOKEN_VALUE=$(awk '$6=="csrf_access_token"{print $7}' cookiesFile)
    : "${CRSF_ACCESS_TOKEN_VALUE:?CSRF token missing}"
    echo "Success"
}

upload_results() {
    echo "------------------PREPARE-RESULTS------------------"
    FILES_TO_SEND=$(ls -dp $ALLURE_RESULTS_DIRECTORY/* | grep -v /$)
    if [ -z "$FILES_TO_SEND" ]; then
        echo "No results found in the specified directory: $ALLURE_RESULTS_DIRECTORY"
        exit 1
    fi

    FILES=''
    for FILE in $FILES_TO_SEND; do
        FILES+="-F files[]=@$FILE "
    done
    echo "Success"

    echo "------------------UPLOAD-RESULTS------------------"
    curl -X POST "$ALLURE_SERVER/allure-api/send-results?project_id=$PROJECT_ID&force_project_creation=true" \
        -H 'Content-Type: multipart/form-data' \
        -H "X-CSRF-TOKEN: $CRSF_ACCESS_TOKEN_VALUE" \
        -b cookiesFile $FILES -k
    echo "Success"

    echo "------------------GENERATE-REPORT------------------"
    EXECUTION_NAME='GitHub-Actions'
    EXECUTION_FROM="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

    GENERATE_URL="$ALLURE_SERVER/allure-api/generate-report?project_id=$PROJECT_ID&execution_name=$EXECUTION_NAME&execution_from=$EXECUTION_FROM&execution_type=github"

    RESPONSE=$(curl -X GET "$GENERATE_URL" -H "X-CSRF-TOKEN: $CRSF_ACCESS_TOKEN_VALUE" -b cookiesFile)
    echo $RESPONSE
    # echo "There is some flackiness in generating link. Temporarily use generic address for the project page and latest report"
    # echo "${ALLURE_SERVER}/allure-ui/allure-docker-service-ui/projects/${PROJECT_ID}/reports/latest"
    echo $(grep -o '"report_url":"[^"]*' <<< "$RESPONSE" | grep -o '[^"]*$')
}

delete_project() {
    echo "------------------DELETE-PROJECT------------------"
    curl -X DELETE "$ALLURE_SERVER/allure-api/projects/$PROJECT_ID" \
        -H "X-CSRF-TOKEN: $CRSF_ACCESS_TOKEN_VALUE" \
        -b cookiesFile -k
    echo "Success"
}

clean_results() {
    echo "------------------CLEAN-RESULTS------------------"
    curl -X GET "$ALLURE_SERVER/allure-api/clean-results?project_id=$PROJECT_ID" \
        -H "X-CSRF-TOKEN: $CRSF_ACCESS_TOKEN_VALUE" \
        -b cookiesFile -k
    echo "Success"
}

if [ "$COMMAND" == "upload" ]; then
    login
    clean_results
    upload_results

elif [ "$COMMAND" == "delete_project" ]; then
    login
    delete_project

elif [ "$COMMAND" == "clean_results" ]; then
    login
    clean_results

else
    echo "Error: Unknown command '$COMMAND'"
    print_usage
    exit 1
fi
