#!/bin/bash
#ls /var/www/current/spec/ | awk '{print $1}' | grep _spec.js | xargs -I % sh -c '{ echo %; /usr/bin/jasmine-node --junitreport /var/www/current/spec/%; sleep 1; }'
cd /var/www/current
RAILS_ENV=production /usr/local/rvm/gems/ruby-2.1.1@global/wrappers/bundle exec rake test:internal
