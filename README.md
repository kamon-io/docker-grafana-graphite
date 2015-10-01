StatsD + Graphite + Grafana 2 + Kamon Dashboards
---------------------------------------------

This image contains a sensible default configuration of StatsD, Graphite and Grafana, and comes bundled with a example
dashboard that gives you the basic metrics currently collected by Kamon for both Actors and Traces. There are two ways
for using this image:


### Using the Docker Index ###

This image is published under [Kamon's repository on the Docker Index](https://index.docker.io/u/kamon/) and all you
need as a prerequisite is having Docker installed on your machine. The container exposes the following ports:

- `80`: the Grafana web interface.
- `8125`: the StatsD port.
- `8126`: the StatsD administrative port.

To start a container with this image you just need to run the following command:

```bash
docker run -d -p 80:80 -p 8125:8125/udp -p 8126:8126 --name kamon-grafana-dashboard kamon/grafana_graphite
```

If you already have services running on your host that are using any of these ports, you may wish to map the container
ports to whatever you want by changing left side number in the `-p` parameters. Find more details about mapping ports
in the [Docker documentation](http://docs.docker.io/use/port_redirection/#port-redirection).

### To keep data and dashboard configuration permanent

Create an empty db file and a directory in the Docker host

```
sudo touch /opt/grafana.db
sudo mkdir /opt/graphite/storage/whisper
```

Attach file and directory as volume

```
docker run -d \
-v /opt/grafana.db:/opt/grafana/data/grafana.db \
-v /opt/graphite/storage/whisper:/opt/graphite/storage/whisper \
-p 80:80 \
-p 8125:8125/udp \
-p 8126:8126 \
--name kamon-grafana-dashboard \
kamon/grafana_graphite
```

### How to run Database and WebApp on different container

Create 2 supervisord configuration file for frontend services (nginx, grafana-webapp, graphite-webapp, dashboard-loader, statsd) and backend service (carbon-cache).

**frontend.conf**
```
[supervisord]
nodaemon = true
environment = GRAPHITE_STORAGE_DIR='/opt/graphite/storage',GRAPHITE_CONF_DIR='/opt/graphite/conf'

[program:nginx]
command = /usr/sbin/nginx
stdout_logfile = /var/log/supervisor/%(program_name)s.log
stderr_logfile = /var/log/supervisor/%(program_name)s.log
autorestart = true

[program:grafana-webapp]
;user = www-data
directory = /opt/grafana/
command = /opt/grafana/bin/grafana-server
stdout_logfile = /var/log/supervisor/%(program_name)s.log
stderr_logfile = /var/log/supervisor/%(program_name)s.log
autorestart = true

[program:graphite-webapp]
;user = www-data
directory = /opt/graphite/webapp
environment = PYTHONPATH='/opt/graphite/webapp'
command = /usr/bin/gunicorn_django -b127.0.0.1:8000 -w2 graphite/settings.py
stdout_logfile = /var/log/supervisor/%(program_name)s.log
stderr_logfile = /var/log/supervisor/%(program_name)s.log
autorestart = true

[program:statsd]
;user = www-data
command = /usr/bin/node /src/statsd/stats.js /src/statsd/config.js
stdout_logfile = /var/log/supervisor/%(program_name)s.log
stderr_logfile = /var/log/supervisor/%(program_name)s.log
autorestart = true

[program:dashboard-loader]
;user = www-data
directory = /src/dashboards
command = /usr/bin/node /src/dashboard-loader/dashboard-loader.js -w .
stdout_logfile = /var/log/supervisor/%(program_name)s.log
stderr_logfile = /var/log/supervisor/%(program_name)s.log
exitcodes = 0
autorestart = unexpected
startretries = 3
```

**backend.conf**
```
[supervisord]
nodaemon = true
environment = GRAPHITE_STORAGE_DIR='/opt/graphite/storage',GRAPHITE_CONF_DIR='/opt/graphite/conf'

[program:carbon-cache]
;user = www-data
command = /opt/graphite/bin/carbon-cache.py --debug start
stdout_logfile = /var/log/supervisor/%(program_name)s.log
stderr_logfile = /var/log/supervisor/%(program_name)s.log
autorestart = true
```

Attach each config file into its respective container

**FRONTEND**
```
docker run -d \
-v /opt/graphite/grafana.db:/opt/grafana/data/grafana.db \
-v /opt/graphite/storage/whisper:/opt/graphite/storage/whisper \
-v /opt/graphite/frontend.conf:/etc/supervisor/conf.d/supervisord.conf \
-p 80:80 \
-p 8125:8125/udp \
-p 8126:8126 \
--name grafana-frontend \
kamon/grafana_graphite
```
**BACKEND**
```
docker run -d \
-v /opt/graphite/grafana.db:/opt/grafana/data/grafana.db \
-v /opt/graphite/storage/whisper:/opt/graphite/storage/whisper \
-v /opt/graphite/backend.conf:/etc/supervisor/conf.d/supervisord.conf \
-p 2003:2003 \
--name grafana-backend \
kamon/grafana_graphite
```

### Building the image yourself ###

The Dockerfile and supporting configuration files are available in our [Github repository](https://github.com/kamon-io/docker-grafana-graphite).
This comes specially handy if you want to change any of the StatsD, Graphite or Grafana settings, or simply if you want
to know how tha image was built. The repo also has `build` and `start` scripts to make your workflow more pleasant.


### Using the Dashboards ###

Once your container is running all you need to do is:
- open your browser pointing to the host/port you just published
- login with the default username (admin) and password (admin)
- configure a new datasource to point at the Graphite metric data (URL - http://localhost:8000) and replace the default Grafana test datasource for your graphs
- then play with the dashboard at your wish...

We hope that you have a lot of fun with this image and that it serves it's
purpose of making your life easier. This should give you an idea of how the dashboard looks like when receiving data
from one of our toy applications:

![Kamon Dashboard](http://kamon.io/assets/img/kamon-statsd-grafana.png)
![System Metrics Dashboard](http://kamon.io/assets/img/kamon-system-metrics.png)
