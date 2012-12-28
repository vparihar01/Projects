var module = angular.module("global.directives", []);

module.directive("csrfTokenized", function() {
  function authenticityToken() {
    return $("meta[name='csrf-token']").attr("content") || "0xDEADBEEF";
  }

  return {
    restrict: "A",
    link: function(scope, elt, attrs, controller) {
      var tag = $("<input/>").attr("type", "hidden");
      tag.attr("name", "authenticity_token");
      tag.attr("value", authenticityToken());
      $(elt).prepend(tag);
    }
  }
})

module.directive("uiModal", ["$timeout", function($timeout) {
  return {
    restrict: "EAC",
    require: "ngModel",
    link: function(scope, elm, attrs, model) {
      //helper so you don"t have to type class="modal hide"
      elm.addClass("modal hide");
      scope.$watch(attrs.ngModel, function(value) {
        elm.modal(value && "show" || "hide");
      });

      elm.on("show.ui", function() {
        $timeout(function() {
          model.$setViewValue(true);
        });
      });
      
      elm.on("hide.ui", function() {
        $timeout(function() {
          model.$setViewValue(false);
        });
      });
    }
  };
}]);

module.directive("viewTabs", function() {
  return {
    restrict: "AC",
    scope: {},
    controller: ["$scope", "$element", "$location", function($scope, $element, $location) {
      var links = [];
      var activeTab = $location.path().substring(1, $location.path().length);
      
      function setActive(title) {
        angular.forEach(links, function(v) {
          if (v.attr("title") == title) {
            v.addClass("active");
          } else {
            v.removeClass("active");
          }
        });
      };

      this.addLink = function (elm, attrs) {
        links.push(elm);

        if (activeTab == elm.attr("title")) {
          setActive(activeTab);
        }
        
        elm.bind("click", function(event) {
          setActive(elm.attr("title"));
        });
      };
    }],
    link: function(scope, elm, attrs, controller) {
    }
  };
});

module.directive("viewTabLink", function() {
  return {
    require: '^viewTabs',
    restrict: 'AC',
    link: function(scope, element, attrs, tabsCtrl) {
      tabsCtrl.addLink(element, attrs);
    }
  };
});

module.directive("fileUploader", function(){
  var fileStatus = function() {
    this._stage = null;
    this._uploadedBytes = 0;
    this._totalBytes = 0;
  }

  fileStatus.prototype.stage = function(nextStage) {
    if (!nextStage) {
      return this._stage;
    }

    this._stage = nextStage;
    return this._stage;
  }

  fileStatus.prototype.failed = function() {
    return this._stage == "failed";
  }

  fileStatus.prototype.ready = function() {
    return this._stage == "ready";
  }

  fileStatus.prototype.successful = function() {
    return this._stage == "successful";
  }

  fileStatus.prototype.uploading = function() {
    return this._stage == "uploading";
  }

  fileStatus.prototype.percentCompleted = function() {
    return Math.ceil((this._uploadedBytes / this._totalBytes) * 100);
  }

  return {
    restrict: "A",
    link: function(scope, elm, attrs) {
      var expression = (attrs.fileUploader);
      var params = scope.$eval(expression);

      scope.uploadWidget = elm.fileupload({
        url: elm[0].action,
        //forceIframeTransport: true,
        singleFileUploads: true,
        sequentialUploads: true,
        dataType: 'json',
        add: function (e, data) {
          data.status = new fileStatus();
          data.status.stage("ready");
          data.status._totalBytes = data.files[0].size;

          scope.$apply(function() {
            scope.files.push(data);
          });

          if (scope.activeUploads > 0) {
            data.submit();
          }

          console.log("add");
          console.log(data);
        },
        always: function (e, data) {
          console.log("always");
          scope.$apply(function(){
            scope.activeUploads--;
          });
        },
        done: function (e, data) {
          console.log("done");
          scope.$apply(function(){
            data.status.stage("successful");
          });
        },
        fail: function (e, data) {
          console.log("fail");
          scope.$apply(function() {
            data.status.stage("failed");
          });
        },
        progress: function (e, data) {
          console.log("progress");
          console.log(data);
          scope.$apply(function(){
            data.status._uploadedBytes = data.loaded;
          });
        },
        progressall: function (e, data) {
          console.log("progressall");
          console.log(data);
          scope.$apply(function(){});
        },
        send: function (e, data) {
          console.log("send");

          scope.$apply(function(){
            data.status.stage("uploading");
          });
        },
        stop: function (e) {
          console.log("stop");
          scope.$apply(function(){});
        },
        submit: function(e, data) {
          scope.$apply(function() {
            scope.activeUploads = scope.activeUploads || 0;
            scope.activeUploads++;
          });
        }
      });
    }
  }
});