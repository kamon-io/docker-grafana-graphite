///// @scratch /configuration/config.js/1
 // == Configuration
 // config.js is where you will find the core Grafana configuration. This file contains parameter that
 // must be set before Grafana is run for the first time.
 ///
define(['settings'],
function (Settings) {


  return new Settings({

    // datasources, you can add multiple
    datasources: {
      graphite: {
        type: 'graphite',
        url: "/graphite",
        default: true
      }
    },

    // elasticsearch url
    // used for storing and loading dashboards, optional
    // For Basic authentication use: http://username:password@domain.com:9200
    elasticsearch: '/elasticsearch', //"http://"+window.location.hostname+":9200",

    // default start dashboard
    default_route: '/dashboard/file/default.json',

    // Elasticsearch index for storing dashboards
    grafana_index: "grafana-dash",

    // timezoneOFfset:
    // If you experiance problems with zoom, it is probably caused by timezone diff between
    // your browser and the graphite-web application. timezoneOffset setting can be used to have Grafana
    // translate absolute time ranges to the graphite-web timezone.
    // Example:
    //   If TIME_ZONE in graphite-web config file local_settings.py is set to America/New_York, then set
    //   timezoneOffset to "-0500" (for UTC - 5 hours)
    // Example:
    //   If TIME_ZONE is set to UTC, set this to "0000"
    //
    timezoneOffset: 0000,

    // set to false to disable unsaved changes warning
    unsaved_changes_warning: true,

    // set the default timespan for the playlist feature
    // Example: "1m", "1h"
    playlist_timespan: "1m",

    // Add your own custom pannels
    plugins: {
      panels: []
    }

  });
});
