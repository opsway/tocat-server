FROM  ruby:2.2.3-slim
MAINTAINER vbykovec@gmail.com
ENV RAILS_ENV=production \
    TOCAT_HOME="/srv/tocat" \
    TOCAT_LOG_DIR="/var/log/tocat"
    SERVER_NAME='test.tocat.opsway.com'
    
RUN apt-get update && apt-get install -qq -y build-essential cron nginx mysql-client libmysqlclient-dev gettext --fix-missing --no-install-recommends
RUN gem install --no-document bundler
WORKDIR ${TOCAT_HOME}
COPY lib/assets/nginx.conf /nginx.conf.tmpl
RUN envsubst '$SERVER_NAME' < /nginx.conf.tmpl > /etc/nginx/nginx.conf
COPY entrypoint.sh /sbin/entrypoint.sh
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install
COPY . .

ENTRYPOINT ["/sbin/entrypoint.sh"]
RUN chmod 755 /sbin/entrypoint.sh
VOLUME ["${TOCAT_LOG_DIR}"]

EXPOSE 443/tcp

CMD ["app:start"]
