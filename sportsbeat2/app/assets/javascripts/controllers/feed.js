function FeedCtrl($scope, $element, $attrs, $transclude, $http) {
  $scope.entries = [];
  $scope.posts = [];
  $scope.fetching = false;

  function is_newer(url) {
    if (!url) {
      return false;
    }

    if (!$scope.newer_url || $scope.newer_url < url) {
      return true;
    } else {
      return false;
    }
  }

  function is_older(url) {
    if (!url) {
      return false;
    }

    if (!$scope.older_url || $scope.older_url > url) {
      return true;
    } else {
      return false;
    }
  }

  $scope.fetch = function(url) {
    if ($scope.fetching) {
      return;
    } else {
      $scope.fetching = true;
    }

    if (!url) {
      url = $scope.url;
    }

    $http({method: 'GET', url: url}).
      success(function(data, status, headers, config) {
        var append = true;

        if (data._links.newer && is_newer(data._links.newer.href)) {
          $scope.newer_url = data._links.newer.href;
          append = false;
        }

        if (data._links.older && is_older(data._links.older.href)) {
          $scope.older_url = data._links.older.href;
        }

        if (append) {
          $scope.entries = $scope.entries.concat(data._embedded.entries);
          $scope.posts = $scope.posts.concat(data._embedded.posts);
        } else {
          $scope.entries = data._embedded.entries.concat($scope.entries);
          $scope.posts = data._embedded.posts.concat($scope.posts);
        }

      });

    $scope.fetching = false;
  }

  $scope.fetch_older = function() {
    $scope.fetch($scope.older_url);
  }

  $scope.fetch_newer = function() {
    $scope.fetch($scope.newer_url);
  }

  $scope.deletePost = function(post) {
    $http.delete(post._links.delete.href, {}).
      success(function(data, status, headers, config) {
        var idx = $scope.posts.indexOf(post);
        Array.remove($scope.posts, idx);
      });
  }

  $scope.$on("newpost", $scope.fetch_newer);
}
FeedCtrl.$inject = ["$scope", "$element", "$attrs", "$transclude", "$http"];

function PostFormCtrl($scope, $element, $attrs, $transclude, $http, $rootScope) {
  $scope.form = $element.find("form");

  $scope.submit = function() {
    $http.post($scope.url, $scope.form.toJSON()).
      success(function(data, status, headers, config) {
        $rootScope.$broadcast("newpost");
        $scope.form[0].reset();
      });
  }
}
PostFormCtrl.$inject = ["$scope", "$element", "$attrs", "$transclude", "$http", "$rootScope"];
