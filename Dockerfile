from ubuntu
run     echo 'deb http://us.archive.ubuntu.com/ubuntu/ precise universe' >> /etc/apt/sources.list
run     apt-get -y update
run     apt-get -y upgrade

# ---------------- #
#   Installation   #
# ---------------- #

# Install all prerequisites 
run apt-get -y install software-properties-common
run     add-apt-repository -y ppa:chris-lea/node.js
run     apt-get -y update
run     apt-get -y install  python-django-tagging python-simplejson python-memcache \
                            python-ldap python-cairo python-django python-twisted   \
                            python-pysqlite2 python-support python-pip gunicorn     \
                            supervisor nginx-light nodejs git wget curl             \ 
                            openjdk-7-jre build-essential python-dev

# Install Elasticsearch
run     cd ~ && wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.1.1.deb
run     cd ~ && dpkg -i elasticsearch-1.1.1.deb && rm elasticsearch-1.1.1.deb

# Install StatsD
run     mkdir /src && git clone https://github.com/etsy/statsd.git /src/statsd

# Install Whisper, Carbon and Graphite-Web
run     pip install Twisted==11.1.0
run     pip install whisper
run     pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/lib" carbon
run     pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/webapp" graphite-web

# Install Grafana
run     mkdir /src/grafana && cd /src/grafana &&\
        wget http://grafanarel.s3.amazonaws.com/grafana-1.5.3.tar.gz &&\
        tar xzvf grafana-1.5.3.tar.gz --strip-components=1 && rm grafana-1.5.3.tar.gz


# ----------------- #
#   Configuration   #
# ----------------- #

# Configure Elasticsearch
add     ./elasticsearch/run /usr/local/bin/run_elasticsearch
run     chown -R elasticsearch:elasticsearch /var/lib/elasticsearch
run     mkdir -p /tmp/elasticsearch && chown elasticsearch:elasticsearch /tmp/elasticsearch

# Confiure StatsD
add     ./statsd/config.js /src/statsd/config.js

# Configure Whisper, Carbon and Graphite-Web
add     ./graphite/initial_data.json /var/lib/graphite/webapp/graphite/initial_data.json
add     ./graphite/local_settings.py /var/lib/graphite/webapp/graphite/local_settings.py
add     ./graphite/carbon.conf /var/lib/graphite/conf/carbon.conf
add     ./graphite/storage-schemas.conf /var/lib/graphite/conf/storage-schemas.conf
run     mkdir -p /var/lib/graphite/storage/whisper
run     touch /var/lib/graphite/storage/graphite.db /var/lib/graphite/storage/index
run     chown -R www-data /var/lib/graphite/storage
run     chmod 0775 /var/lib/graphite/storage /var/lib/graphite/storage/whisper
run     chmod 0664 /var/lib/graphite/storage/graphite.db
run     cd /var/lib/graphite/webapp/graphite && python manage.py syncdb --noinput

# Configure Grafana
add     ./grafana/config.js /src/grafana/config.js
add     ./grafana/scripted.json /src/grafana/app/dashboards/default.json

# Configure nginx and supervisord
add     ./nginx/nginx.conf /etc/nginx/nginx.conf
add     ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf


# Expose ports
# Graphite
expose  80

# Grafana
expose  81

# Carbon line receiver port
expose  2003

# Carbon pickle receiver port
expose  2004

# Carbon cache query port
expose  7002

# Statsd UDP port
expose  8125/udp

# Statsd Management port
expose  8126


cmd     ["/usr/bin/supervisord"]