#!/bin/bash
cd cd /var/www/current
source /usr/local/rvm/rubies/ruby-2.1.1/bin/ruby
rake RAILS_ENV=production shiftplanning:test
