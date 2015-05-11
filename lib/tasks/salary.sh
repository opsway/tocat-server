#!/bin/bash
cd /var/www/current
source /usr/local/rvm/rubies/ruby-2.1.1/bin/ruby
RAILS_ENV=production rake shiftplanning:update_transactions
