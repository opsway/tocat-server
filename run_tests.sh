#!/bin/sh
ls /var/www/current/spec/ | awk '{print $1}' | grep _spec.js | xargs -I % sh -c '{ echo %; cd /var/www/current && RAILS_ENV=production bundle exec rake sql_data:load && /usr/bin/jasmine-node --junitreport /var/www/current/spec/%; sleep 1; }'
