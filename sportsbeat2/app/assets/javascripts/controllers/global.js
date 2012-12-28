function FileUploadExampleCtrl($scope, $routeParams, $timeout) {
  $scope.files = [];
  $scope.activeUploads = 0;

  $scope.startUploading = function() {
    angular.forEach($scope.files, function(info, index) {
      if (info.status.ready()) {
        $timeout(function() { info.submit(); });
      }
    });
  }

  $scope.dequeueFile = function(file) {
    if (!file.status.ready()) {
      return;
    }

    var idx = $scope.files.indexOf(file);
    if (idx != -1) {
      $scope.files.splice(idx, 1);
    }

    if (file.jqXHR) {
      $timeout(function() { file.jqXHR.abort(); });
    }
  }
}

FileUploadExampleCtrl.$inject = ["$scope", "$routeParams", "$timeout"];