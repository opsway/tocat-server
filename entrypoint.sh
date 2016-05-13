#!/bin/bash
set -e

[[ $DEBUG == true ]] && set -x

case ${1} in
  app:init|app:start|app:rake)

    case ${1} in
      app:start)
        cd $TOCAT_HOME && bundle exec rake db:migrate
        cd $TOCAT_HOME && bundle exec thin start -C config/thin.yml
        ;;
      app:init)
        bundle exec rake db:create
        bundle exec rake db:migrate
        ;;
      app:rake)
        shift 1
        execute_raketask $@
        ;;
    esac
    ;;
  app:help)
    echo "Available options:"
    echo " app:start          - Starts the tocat server (default)"
    echo " app:init           - Initialize the tocat server (e.g. create databases), but don't start it."
    echo " app:rake <task>    - Execute a rake task."
    echo " [command]          - Execute the specified command, eg. bash."
    ;;
  *)
    exec "$@"
    ;;
esac
