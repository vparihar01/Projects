var module = angular.module("global", ["global.directives", "global.filters", "global.services", "bootstrap"]);

module.config(["$httpProvider", function(provider) { 
  provider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content');
}]);