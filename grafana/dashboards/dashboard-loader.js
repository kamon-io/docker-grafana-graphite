var fs = require('fs');
var http = require('http');

var args = process.argv.slice(2);

setTimeout( function() {
  args.forEach(function (file_name) {
    var dashboard_file = fs.readFileSync(file_name, "utf8");
    var dashboard_resource = '/elasticsearch/grafana-dash/dashboard/' + file_name.split('.')[0];
    var dashboard = JSON.parse(dashboard_file);

    http.get({
      host: 'localhost',
      path: dashboard_resource

    }, function(response) {
      var body = '';
      response.on('data', function(d) {
        body += d;
      });
      response.on('end', function() {
        var search_result = JSON.parse(body);
        if(!search_result.found) {
          var dashboard_data = {
            user: 'guest',
            group: 'guest',
            title: dashboard.title,
            tags: [],
            dashboard: JSON.stringify(dashboard)
          }

          var put_request = http.request({
            host: 'localhost',
            path: dashboard_resource,
            method: 'PUT'
          })

          put_request.write(JSON.stringify(dashboard_data));
          put_request.end();

          console.log('Added the [' + dashboard.title + '] dashboard.');
        } else {
          console.log('Dashboard [' + dashboard.title + '] was already present.');
        }

      });
    })
  })
}, 20000);



// Starting the web server just to keep the process running.
http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('You should not talk to me!\n');
}).listen(1337, '127.0.0.1');
