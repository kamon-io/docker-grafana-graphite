define(['settings'],
function (Settings) {
  return new Settings({

    datasources: {
      graphite: {
        type: 'graphite',
        url: "/graphite",
      },
      elasticsearch: {
        type: 'elasticsearch',
        url: "/elasticsearch",
        index: 'grafana-dash',
        grafanaDB: true,
      }
    },

    // default start dashboard
    default_route: '/dashboard/db/welcome',

    // Elasticsearch index for storing dashboards
    grafana_index: "grafana-dash",

    // specify the limit for dashboard search results
    search: {
      max_results: 20
    },

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
