FROM ubuntu:16.04 as base

ENV DEBIAN_FRONTEND=noninteractive TERM=xterm
RUN echo "export > /etc/envvars" >> /root/.bashrc && \
    echo "export PS1='\[\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" | tee -a /root/.bashrc /etc/skel/.bashrc && \
    echo "alias tcurrent='tail /var/log/*/current -f'" | tee -a /root/.bashrc /etc/skel/.bashrc

RUN apt-get update
RUN apt-get install -y locales && locale-gen en_US.UTF-8 && dpkg-reconfigure locales
ENV LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD bash -c 'export > /etc/envvars && /usr/sbin/runsvdir-start'

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute python ssh rsync gettext-base

# Add stable StackStorm repos:
RUN curl -s https://packagecloud.io/install/repositories/StackStorm/staging-stable/script.deb.sh | bash

# Install all StackStorm components and mistral:
RUN apt-get install -y st2 st2mistral st2web

# Install Nginx:
RUN apt-get install -y nginx

# Flat file auth
RUN apt-get install -y apache2-utils

# ChatOps
RUN curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
RUN apt-get install -y st2chatops

# Setup system user
RUN mkdir -p /home/stanley/.ssh && \
    chmod 0700 /home/stanley/.ssh && \
    ssh-keygen -f /home/stanley/.ssh/stanley_rsa -P "" && \
    cat /home/stanley/.ssh/stanley_rsa.pub >> /home/stanley/.ssh/authorized_keys && \
    chown -R stanley:stanley /home/stanley/.ssh && \
    echo "stanley    ALL=(ALL)       NOPASSWD: SETENV: ALL" >> /etc/sudoers.d/st2 && \
    chmod 0440 /etc/sudoers.d/st2 && \
    sed -i -r "s/^Defaults\s+\+?requiretty/# Defaults +requiretty/g" /etc/sudoers

# Nginx config
RUN rm /etc/nginx/sites-enabled/* || true
COPY etc/nginx.conf /etc/nginx/sites-enabled/st2.conf
COPY etc/template/config.js /opt/stackstorm/static/webui/config.js

# Config template files
COPY etc/template /etc/template

# Auth config
ENV ST2_AUTH_USERNAME=admin \
    ST2_AUTH_PASSWORD=admin

# ST2 config
ENV MONGODB_HOST=stackstorm-mongodb \
    RABBITMQ_URL=rabbit://admin:admin@stackstorm-rabbitmq:5672 \
    AMQP_URL=amqp://admin:admin@stackstorm-rabbitmq:5672 \
    POSTGRES_URL=postgresql://mistral:StackStorm@stackstorm-postgres/mistral

# ChatOps config
ENV HUBOT_ADAPTER=slack \
    HUBOT_SLACK_TOKEN=your_slack_token

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO

