#!/bin/bash
# sleeping for 10 seconds to let grafana get up and running
sleep 10 && curl 'http://admin:admin@localhost:80/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"Local Graphite","type":"graphite","url":"http://localhost:8000","access":"proxy","isDefault":true}'
