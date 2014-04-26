StatsD + Graphite + Grafana + Kamon Dashboard
-------

This image contains a sensible default configuration of statsd, graphite and
carbon-cache. Starting this container will, by default, bind the the following
host ports:

- `81`: the grafana web interface
- `8125`: the statsd port

if you already have services running on the host on one or more of these ports, you may wish to map the docker ports with the host ports. You can do this easily by running:

     docker run -d -p 81:81 -p 8125:8125/udp  kamon/grafana_graphite

finally the Kamon dashboard looks like this: 
![Kamon Dashboard][1]


  [1]: http://kamon.io/assets/img/kamon-statsd-grafana.png
