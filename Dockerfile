FROM  ruby:2.2.3-slim
MAINTAINER vbykovec@gmail.com
ENV RAILS_ENV=production \
    TOCAT_HOME="/srv/tocat" \
    TOCAT_LOG_DIR="/var/log/tocat" 
    
RUN apt-get update && apt-get install -qq -y git build-essential cron rsyslog sendmail mysql-client libmysqlclient-dev gettext --fix-missing --no-install-recommends
RUN gem install --no-document bundler
WORKDIR ${TOCAT_HOME}
COPY entrypoint.sh /sbin/entrypoint.sh
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN git config --global url."https://".insteadOf git://
RUN bundle install
COPY . .

ENTRYPOINT ["/sbin/entrypoint.sh"]
RUN chmod 755 /sbin/entrypoint.sh
VOLUME ["${TOCAT_LOG_DIR}"]

EXPOSE 3000/tcp

CMD ["app:start"]
