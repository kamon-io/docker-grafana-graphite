#!/bin/sh

###Install Zabbix Backend Pluggin
/opt/grafana/bin/grafana-cli --pluginsDir /opt/grafana/data/plugins plugins install alexanderzobnin-zabbix-app

/usr/bin/supervisord --nodaemon --configuration /etc/supervisor/conf.d/supervisord.conf
