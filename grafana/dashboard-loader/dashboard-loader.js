var fs = require('fs');
var http = require('http');
var ini = require('ini');
var chokidar = require('chokidar');

var noop = function(d){};

var default_config = ini.parse(fs.readFileSync('/opt/grafana/conf/defaults.ini', 'utf-8'));
var custom_config = ini.parse(fs.readFileSync('/opt/grafana/conf/custom.ini', 'utf-8'));

var user = custom_config.security.admin_user || default_config.security.admin_user;
var password = custom_config.security.admin_password || default_config.security.admin_password;
var cookies = [];
var watcher;
var file_name_to_slug = {};

var upsertDashboard = function(dashboard_data, callback) {
  console.log('Adding/updating the [' + dashboard_data.title + '] dashboard.');
  var update_request = http.request({
    method: 'POST',
    path: '/api/dashboards/db/',
    headers: {
      'Content-Type': 'application/json',
      'Cookie': cookies
    }
  }, function(res) {
      var res_body = '';
      res.on('data', function(chunk) {
          res_body += chunk;
      });
      res.on('end', function() {
        if(res.statusCode == 200) {
          var slug = (JSON.parse(res_body)).slug;
          dashboardExists(slug, function(exists) {
            if(exists) {
              callback(slug);
            } else {
              upsertDashboard(dashboard_data, callback);
            }
          });
        } else {
          console.log('When adding/updating the [' + dashboard_data.title + '] dashboard, I got a ' + res.statusCode + ': ' + res_body);
        }
      });
      switch(res.statusCode) {
        case 200:
          console.log('Added the [' + dashboard_data.title + '] dashboard.');
          break;
        case 401:
          getGrafanaSess(function() {
            upsertDashboard(dashboard_data, callback);
          });
          break;
        case 404:
          setTimeout(function() {
            upsertDashboard(dashboard_data, callback);
          }, 1000);
      } 
      
  });
  
  update_request.on('error', function(e) {
    console.log('Error trying to create/update the [' + dashboard_data.title + '] dashboard: ' + e);
  });
  
  update_request.write(JSON.stringify({dashboard:dashboard_data, overwrite: true}));
  update_request.end();
}

var dashboardExists = function(slug, callback) {
  console.log('Checking existence of dashboard with slug ' + slug);
  var get_request = http.request({
    method: 'GET',
    path: '/api/dashboards/db/' + slug,
    headers: {
      'Cookie': cookies
    }
  }, function(res) {
    res.on('data', noop);
    switch(res.statusCode) {
        case 200:
          console.log('The dashboard with slug ' + slug + ' exists');
          callback(true);
          break;
        case 404:
          console.log('The dashboard with slug ' + slug + ' doesn\'t exist');
          callback(false);
          break;
        case 401:
          getGrafanaSess(function() {
            dashboardExists(slug, callback);
          });
          break;
      } 
  });
  
  get_request.on('error', function(e) {
    console.log('Error trying to verify the existence of the dashboard with slug ' + slug + ': ' + e);
  });
  
  get_request.end();
}

var deleteDashboard = function(slug) {
  console.log('Deleting the dashboard with slug ' + slug);
  var delete_request = http.request({
    method: 'DELETE',
    path: '/api/dashboards/db/' + slug,
    headers: {
      'Cookie': cookies
    }
  }, function(res) {
      res.on('data', noop);
      switch(res.statusCode) {
        case 200:
          console.log('Successfully removed dashboard with slug ' + slug);
          break;
        case 401:
          getGrafanaSess(function() {
            deleteDashboard(slug);
          });
          break;
      } 
      
  });
  
  delete_request.on('error', function(e) {
    console.log('Error trying to delete the dashboard with slug ' + slug + ': ' + e);
  });
  
  delete_request.end();
}

var getGrafanaSess = function(callback) {
  var login_request = http.request({
    method: 'POST',
    path: '/login',
    headers: {
      'Content-Type': 'application/json'
    }
  }, function(res) {
    res.on('data', noop);
    if(res.statusCode == 200) {
      console.log('Logged in');
      cookies = res.headers['set-cookie'].map(function(cookie){
          return cookie.split(';')[0];
      }).join(';');
      callback();
    } else {
      console.log('Wrong credentials');
    }
  });
  login_request.on('error', function(e) {
    console.log('Error trying to login ' + e);
  });
  login_request.write(JSON.stringify({user: user, email: '', password: password}));
  login_request.end();
}

var upsertDashboardFromFile = function(file_name, callback) {
  var dashboard_file = fs.readFileSync(file_name, "utf8");
  var dashboard_data = JSON.parse(dashboard_file);
  upsertDashboard(dashboard_data, function(slug) {
    console.log('Dashboard file ' + file_name + ' has been loaded with slug ' + slug);
    callback(slug);
  });
}

var retryPing = function(callback) {
  setTimeout(function() {
    pingGrafana(callback);
  }, 1000);
}

var pingGrafana = function(callback) {
  console.log('Pinging grafana login page...');
  var ping_request = http.request({
    path: '/login'
  }, function(res) {
    res.on('data', noop);
    console.log('Got status code ' + res.statusCode + ' from login page');
    if(res.statusCode == 200) {
      callback();
    } else {
      retryPing(callback);
    }
  });
  ping_request.on('error', function(e) {
    console.log('Error trying to get login page ' + e);
    retryPing(callback);
  });
  ping_request.end();
}

pingGrafana(function() {
  getGrafanaSess(function() {
    var args = process.argv.slice(2);
    var watch = args[0] == '-w';
    if(watch) {
      args = args.slice(1);
    }
    watcher = chokidar.watch(args, {
      ignored: /[\/\\]\./,
      persistent: true
    });
    watcher.on('add', function(path) {
      upsertDashboardFromFile(path, function(slug){
        file_name_to_slug[path] = slug;
      });
    });
    watcher.on('change', function(path) {
      var previous_slug = file_name_to_slug[path];
      upsertDashboardFromFile(path, function(slug) {
        if(slug != previous_slug) {
          deleteDashboard(previous_slug);
        }
      });
    });
    watcher.on('unlink', function(path) {
      var slug_to_delete = file_name_to_slug[path];
      if(slug_to_delete) {
        deleteDashboard(slug_to_delete);
        delete file_name_to_slug[path];
      }
    });
    watcher.on('ready', function() {
      if(!watch) {
        watcher.close();
      }
    });
  });
});



