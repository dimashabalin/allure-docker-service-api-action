# GitHub action API for Allure Docker Service
[![GitHub release badge](https://badgen.net/github/release/dimashabalin/allure-docker-service-api-action)](https://github.com/dimashabalin/allure-docker-service-api-action/releases/latest)

Create&Upload&CleanUp for [fescobar/allure-docker-service](https://github.com/fescobar/allure-docker-service).

## Inputs

#### `command`
1. `upload` - login -> create project if needed -> clean & upload results -> generates report
1. `clean_results` - login -> clean results
1. `delete_project` - login -> delete project

Default - `upload`

______

#### `project_id` 
project id in docker service, recommend to use branch name

Default - `unknown`

______

#### `allure_results`

allure results directory to upload

Default - `allure-results/`

______

## Secrets
Server url and Authorization are **required** and must be specified using these ENV vars:
- `ALLURE_SERVER_URL`
- `ALLURE_SERVER_USER`
- `ALLURE_SERVER_PASSWORD`
#### [How to set secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

## Misc
`GITHUB_SERVER_URL`, `GITHUB_REPOSITORY`, `GITHUB_RUN_ID` are also used to add link in the report to come back to the specific run

## Example usage

```yml
jobs:
  allure-upload-results-example:
    runs-on: ubuntu-latest

    name: Upload to Allure Docker Service

    env:
      ALLURE_SERVER_URL: ${{ secrets.ALLURE_SERVER_URL }}
      ALLURE_SERVER_USER: ${{ secrets.ALLURE_SERVER_USER }}
      ALLURE_SERVER_PASSWORD: ${{ secrets.ALLURE_SERVER_PASSWORD }}

    steps:
      - uses: actions/checkout@v2

      - uses: dimashabalin/allure-docker-service-api-action@v1
        with:
          allure_results: upload
```
