#!/bin/bash
#
# steps for every required repo:
#  - clone master
#  - clean local static analysis tools configurations
#  - copy default static analysis configs
#  - run analysis
#  - send results do sonarqube
#
#

REPOSITORIES_NAMESPACE="git@github.com:nowaja"
REPOSITORIES="sonarqube-example"
NUM_OF_PARALLEL=2

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SONAR_URL=$1
SONAR_TOKEN=$2

fail()
{
    echo "$1"
    exit 1
}

pwait()
{
    while [ $(jobs -p | wc -l) -ge $1 ]; do
        sleep 1
    done
}

prepare_repo()
{
  echo "PREPARE repo $1: $2"

  cleanup "$2"
  git clone "$1" "$2" || fail "can't clone repo $2"
  cd "$2"
  composer install --ignore-platform-reqs --no-interaction --prefer-dist --no-progress

  echo "PREPARED";
}

cleanup()
{
  echo "CLEANUP $1"

  rm -rf "$1"
  cd "$SCRIPT_DIR"

  echo "CLEANED UP"
}

remove_local_configs()
{
  echo "REMOVE repo static analysis configs"

  cd "$REPOSITORY_FOLDER"
  rm -f psalm.xml psalm-baseline.xml phpstan.neon phpstan.neon.dist phpstan-baseline.neon depfile.yaml sonar-project.properties

  echo "REMOVED";
}

create_default_configs()
{
    echo "COPY default configs"

    cd "$REPOSITORY_FOLDER"

    for FILE in "phpstan.neon" "psalm.xml" "depfile.yaml" "sonar-project.properties"
    do
      if [ -f "$FILE" ]
      then
          echo "$FILE already exists. SKIPPING"
      else
          echo "COPYING $FILE"
          cp "${SCRIPT_DIR}/default-configs/${FILE}" "${FILE}"
      fi
    done

    echo "..DONE."
}

generate_sonar_project_properties_file()
{
  echo "CREATE sonar-project.properties"

  cd "$REPOSITORY_FOLDER"

  sed -i '' -e "s/{PROJECT-KEY}/$1/g" sonar-project.properties

  echo "CREATED"
}

run_analysis()
{
  echo "RUN ANALYSIS"

  cd "$REPOSITORY_FOLDER"
  mkdir -p test-reports

  docker run --rm -v $(pwd):/app nowaja/deptrac:0.15.2 analyze --formatter=json --json-dump=test-reports/deptrac-report.json /app/depfile.yaml
  docker run --rm -v $(pwd):/app nowaja/psalm:4.15.0 --output-format=sonarqube --report=test-reports/sonarqube.json
  docker run --rm -v $(pwd):/app ghcr.io/phpstan/phpstan:0.12.89 analyse -c phpstan.neon --error-format=json > test-reports/phpstan-report.json

  echo "ANALYSED"
}

send_analysis_to_sonarqube()
{
  echo "$SCRIPT_DIR/../bin"
  cd "$SCRIPT_DIR/../bin"

  ./transform-deptrac-results-for-sonarqube "$REPOSITORY_FOLDER/test-reports/deptrac-report.json"

  cd "$REPOSITORY_FOLDER"

  docker run --rm --network=mynetwork \
    -e SONAR_HOST_URL="$SONAR_URL" \
    -e SONAR_LOGIN="$SONAR_TOKEN" \
    -v "$(PWD):/app" \
    sonarsource/sonar-scanner-cli \
    -D sonar.projectBaseDir=/app

  echo "REPORTS SENT TO SONARQUBE"
}

process_repository()
{
  REPOSITORY_FOLDER="$SCRIPT_DIR/repositories/$1"

  echo "REPOSITORY_FOLDER $REPOSITORY_FOLDER"

  prepare_repo "$REPOSITORIES_NAMESPACE/$1.git" "$REPOSITORY_FOLDER"
  remove_local_configs
  create_default_configs
  run_analysis "$1"
  generate_sonar_project_properties_file "$1"
  send_analysis_to_sonarqube
  cleanup "$REPOSITORY_FOLDER"
}

for REPOSITORY in $REPOSITORIES
do
  process_repository "$REPOSITORY" &
  pwait $NUM_OF_PARALLEL
done

wait
exit 0;
