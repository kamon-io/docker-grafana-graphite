#!/bin/bash
# sleeping for 10 seconds to let grafana get up and running
sleep 10 && wizzy export datasources && wizzy export dashboards
