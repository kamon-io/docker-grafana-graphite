FROM   alpine

# ---------------- #
#   Installation   #
# ---------------- #

# Install all prerequisites
RUN     apk add --update --no-cache nginx nodejs nodejs-npm git curl wget gcc ca-certificates \
                                    python-dev py-pip musl-dev libffi-dev cairo supervisor bash \
                                    py-pyldap py-rrd                                                                 &&\
        wget -q -O /etc/apk/keys/sgerrand.rsa.pub \
                    https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub              &&\
        wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.26-r0/glibc-2.26-r0.apk                &&\
        apk add --no-cache  glibc-2.26-r0.apk                                                                        &&\
        rm glibc-2.26-r0.apk                                                                                         &&\
        adduser -D -u 1000 -g 'www' www                                                                              &&\
        pip install -U pip pytz gunicorn six --no-cache-dir                                                          &&\
        npm install -g wizzy                                                                                         &&\
        npm cache clean --force

# Checkout the master branches of Graphite, Carbon and Whisper and install from there
RUN     mkdir /src                                                                                                   &&\
        git clone --depth=1 --branch master https://github.com/graphite-project/whisper.git /src/whisper             &&\
        cd /src/whisper                                                                                              &&\
        pip install . --no-cache-dir                                                                                 &&\
        python setup.py install

RUN     git clone --depth=1 --branch master https://github.com/graphite-project/carbon.git /src/carbon               &&\
        cd /src/carbon                                                                                               &&\
        pip install . --no-cache-dir                                                                                 &&\
        python setup.py install

RUN     git clone --depth=1 --branch master https://github.com/graphite-project/graphite-web.git /src/graphite-web   &&\
        cd /src/graphite-web                                                                                         &&\
        pip install . --no-cache-dir                                                                                 &&\
        python setup.py install                                                                                      &&\
        pip install -r requirements.txt --no-cache-dir                                                               &&\
        python check-dependencies.py

# Install StatsD
RUN     git clone --depth=1 --branch master https://github.com/etsy/statsd.git /src/statsd

# Install Grafana
RUN     mkdir /src/grafana                                                                                           &&\
        mkdir /opt/grafana                                                                                           &&\
        curl https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-4.6.3.linux-x64.tar.gz \
             -o /src/grafana.tar.gz                                                                                  &&\
        tar -xzf /src/grafana.tar.gz -C /opt/grafana --strip-components=1                                            &&\
        rm /src/grafana.tar.gz


# Cleanup Compile Dependencies
RUN     apk del --no-cache git curl wget gcc python-dev musl-dev libffi-dev


# ----------------- #
#   Configuration   #
# ----------------- #

# Confiure StatsD
ADD     ./statsd/config.js /src/statsd/config.js

# Configure Whisper, Carbon and Graphite-Web
ADD     ./graphite/initial_data.json /opt/graphite/webapp/graphite/initial_data.json
ADD     ./graphite/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
ADD     ./graphite/carbon.conf /opt/graphite/conf/carbon.conf
ADD     ./graphite/storage-schemas.conf /opt/graphite/conf/storage-schemas.conf
ADD     ./graphite/storage-aggregation.conf /opt/graphite/conf/storage-aggregation.conf
RUN     mkdir -p /opt/graphite/storage/whisper                                                                       &&\
        mkdir -p /opt/graphite/storage/log/webapp                                                                    &&\
        touch /opt/graphite/storage/graphite.db /opt/graphite/storage/index                                          &&\
        chown -R www /opt/graphite/storage                                                                           &&\
        chmod 0775 /opt/graphite/storage /opt/graphite/storage/whisper                                               &&\
        chmod 0664 /opt/graphite/storage/graphite.db                                                                 &&\
        cp /src/graphite-web/webapp/manage.py /opt/graphite/webapp                                                   &&\
        cd /opt/graphite/webapp/ && python manage.py migrate --run-syncdb --noinput

# Configure Grafana and wizzy
ADD     ./grafana/custom.ini /opt/grafana/conf/custom.ini
RUN     cd /src                                                                                                      &&\
        wizzy init                                                                                                   &&\
        extract() { cat /opt/grafana/conf/custom.ini | grep $1 | awk '{print $NF}'; }                                &&\
        wizzy set grafana url $(extract ";protocol")://$(extract ";domain"):$(extract ";http_port")                  &&\
        wizzy set grafana username $(extract ";admin_user")                                                          &&\
        wizzy set grafana password $(extract ";admin_password")

# Add the default datasource and dashboards
RUN 	mkdir /src/datasources                                                                                       &&\
        mkdir /src/dashboards
ADD     ./grafana/datasources/* /src/datasources
ADD     ./grafana/dashboards/* /src/dashboards/
ADD     ./grafana/export-datasources-and-dashboards.sh /src/

# Configure nginx and supervisord
ADD     ./nginx/nginx.conf /etc/nginx/nginx.conf
RUN     mkdir /var/log/supervisor
ADD     ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf


# ---------------- #
#   Expose Ports   #
# ---------------- #

# Grafana
EXPOSE  80

# StatsD UDP port
EXPOSE  8125/udp

# StatsD Management port
EXPOSE  8126

# Graphite web port
EXPOSE 81

# Graphite Carbon port
EXPOSE 2003


# -------- #
#   Run!   #
# -------- #

CMD     ["/usr/bin/supervisord", "--nodaemon", "--configuration", "/etc/supervisor/conf.d/supervisord.conf"]
