function DashboardCtrl($scope) {
  var preloaded_data = JSON.parse($("#preloaded_json").text());
  
  $scope.feedUrl = preloaded_data.feed_url;
  $scope.gameScheduleUrl = preloaded_data.game_schedule_url;
  $scope.postToUrl = preloaded_data.post_to_url;
}
DashboardCtrl.$inject = ["$scope"];