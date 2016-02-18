StatsD + Graphite + Grafana 2 + Kamon Dashboards
---------------------------------------------

This image contains a sensible default configuration of StatsD, Graphite and Grafana, and comes bundled with a example
dashboard that gives you the basic metrics currently collected by Kamon for both Actors and Traces. There are two ways
for using this image:


### Using the Docker Index ###

This image is published under [Kamon's repository on the Docker Hub](https://hub.docker.com/u/kamon/) and all you
need as a prerequisite is having Docker installed on your machine. The container exposes the following ports:

- `80`: the Grafana web interface.
- `81`: the Graphite web port
- `8125`: the StatsD port.
- `8126`: the StatsD administrative port.

To start a container with this image you just need to run the following command:

```bash
docker run \
  --detach \
   --publish=80:80 \
   --publish=81:81 \
   --publish=8125:8125/udp \
   --publish=8126:8126 \
   --name kamon-grafana-dashboard \
   kamon/grafana_graphite
```

If you already have services running on your host that are using any of these ports, you may wish to map the container
ports to whatever you want by changing left side number in the `--publish` parameters. You can omit ports you do not plan to use. Find more details about mapping ports in the Docker documentation on [Binding container ports to the host](https://docs.docker.com/engine/userguide/networking/default_network/binding/) and [Legacy container links](https://docs.docker.com/engine/userguide/networking/default_network/dockerlinks/).


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

### Making your data last ###

There are several ways of using Docker volumes to persist the settings and databases of the docker-grafana-graphite container. Here is an example script that will create directories on your host and mount them into the Docker container, allowing graphite and grafana to persist data and settings between runs of the container.

```bash
mkdir kamon-grafana-service
cd kamon-grafana-service
mkdir -p data/whisper
mkdir -p data/elasticsearch
mkdir -p data/grafana
mkdir -p log/graphite
mkdir -p log/graphite/webapp
mkdir -p log/elasticsearch
chmod -R 777 *

docker run \
  --detach \
   --publish=80:80 \
   --publish=81:81 \
   --publish=8125:8125/udp \
   --publish=8126:8126 \
   --name kamon-grafana-dashboard \
   --volume=$(pwd)/data/whisper:/opt/graphite/storage/whisper \
   --volume=$(pwd)/data/elasticsearch:/var/lib/elasticsearch \
   --volume=$(pwd)/data/grafana:/opt/grafana/data \
   --volume=$(pwd)/log/graphite:/opt/graphite/storage/log \
   --volume=$(pwd)/log/elasticsearch:/var/log/elasticsearch \
   kamon/grafana_graphite
```

### Now go explore! ###

We hope that you have a lot of fun with this image and that it serves it's
purpose of making your life easier. This should give you an idea of how the dashboard looks like when receiving data
from one of our toy applications:

![Kamon Dashboard](http://kamon.io/assets/img/kamon-statsd-grafana.png)
![System Metrics Dashboard](http://kamon.io/assets/img/kamon-system-metrics.png)
