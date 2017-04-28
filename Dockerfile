FROM     ubuntu:14.04

# ---------------- #
#   Installation   #
# ---------------- #

ENV DEBIAN_FRONTEND noninteractive

# Install all prerequisites
RUN     apt-get -y update &&\ 
	apt-get -y install software-properties-common python-django-tagging python-simplejson \
	python-memcache python-ldap python-cairo python-pysqlite2 python-support python-pip \
	gunicorn supervisor nginx-light git wget curl openjdk-7-jre build-essential python-dev libffi-dev

RUN     pip install Twisted==13.2.0
RUN     pip install pytz
RUN	curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
RUN	apt-get install -y nodejs
RUN	npm install -g wizzy

# Checkout the stable branches of Graphite, Carbon and Whisper and install from there
RUN     mkdir /src
RUN     git clone https://github.com/graphite-project/whisper.git /src/whisper            &&\
        cd /src/whisper                                                                   &&\
        git checkout 1.0.x                                                                &&\
        python setup.py install

RUN     git clone https://github.com/graphite-project/carbon.git /src/carbon              &&\
        cd /src/carbon                                                                    &&\
        git checkout 1.0.x                                                                &&\
        python setup.py install


RUN     git clone https://github.com/graphite-project/graphite-web.git /src/graphite-web  &&\
        cd /src/graphite-web                                                              &&\
	git checkout 1.0.x								  &&\
        python setup.py install                                                           &&\
        pip install -r requirements.txt                                                   &&\
        python check-dependencies.py

# Install StatsD
RUN     git clone https://github.com/etsy/statsd.git /src/statsd                          &&\
        cd /src/statsd                                                                    &&\
        git checkout v0.8.0


# Install Grafana
RUN     mkdir /src/grafana                                                                                    &&\
        mkdir /opt/grafana                                                                                    &&\
        wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-4.2.0.linux-x64.tar.gz -O /src/grafana.tar.gz &&\
        tar -xzf /src/grafana.tar.gz -C /opt/grafana --strip-components=1                                     &&\
        rm /src/grafana.tar.gz


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
RUN     mkdir -p /opt/graphite/storage/whisper
RUN     touch /opt/graphite/storage/graphite.db /opt/graphite/storage/index
RUN     chown -R www-data /opt/graphite/storage
RUN     chmod 0775 /opt/graphite/storage /opt/graphite/storage/whisper
RUN     chmod 0664 /opt/graphite/storage/graphite.db
RUN     cp /src/graphite-web/webapp/manage.py /opt/graphite/webapp
RUN     cd /opt/graphite/webapp/ && python manage.py migrate --run-syncdb --noinput

# Configure Grafana and wizzy
ADD     ./grafana/custom.ini /opt/grafana/conf/custom.ini
RUN	cd /src && wizzy init 										&&\
	extract() { cat /opt/grafana/conf/custom.ini | grep $1 | awk '{print $NF}'; }			&&\
	wizzy set grafana url $(extract ";protocol")://$(extract ";domain"):$(extract ";http_port")	&&\		
	wizzy set grafana username $(extract ";admin_user")						&&\
	wizzy set grafana password $(extract ";admin_password")
# Add the default datasource and dashboards
RUN 	mkdir /src/datasources
ADD	./grafana/datasources/* /src/datasources
RUN     mkdir /src/dashboards
ADD     ./grafana/dashboards/* /src/dashboards/
ADD     ./grafana/export-datasources-and-dashboards.sh /src/

# Configure nginx and supervisord
ADD     ./nginx/nginx.conf /etc/nginx/nginx.conf
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



# -------- #
#   Run!   #
# -------- #

CMD     ["/usr/bin/supervisord"]

