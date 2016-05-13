FROM  ruby:2.2.3-slim
MAINTAINER vbykovec@gmail.com
ENV RAILS_ENV=production \
    TOCAT_HOME="/srv/tocat" \
    TOCAT_LOG_DIR="/var/log/tocat" \
    
RUN apt-get update && apt-get install -qq -y build-essential nodejs nginx mysql-client --fix-missing --no-install-recommends
RUN gem install --no-document bundler
WORKDIR ${TOCAT_HOME}
COPY lib/assets/nginx.conf /etc/nginx/conf/
COPY entrypoint.sh /sbin/entrypoint.sh
COPY Gemfile Gemfile
RUN bundle install
COPY . .

RUN bundle exec rake db:migrate

ENTRYPOINT ["/sbin/entrypoint.sh"]
RUN chmod 755 /sbin/entrypoint.sh
VOLUME ["#{TOCAT_LOG_DIR}"]

EXPOSE 80/tcp 443/tcp

CMD ["app:start"]