document.observe("dom:loaded", function(){
  $('form_filter')
  .observe('ajax:before', function(evt, xhr, settings){
    if ($('error')) $('error').replace();
    showIndicatorOverDiv('results');
    return false;
  })
  .observe('ajax:success', function(evt, data, status, xhr){
    return false;
  })
  .observe('ajax:complete', function(evt, data, status, xhr){
    hideIndicatorOverDiv('results');
    return false;
  })
  .observe('ajax:failure', function(evt, data, status, xhr){
    $('content').insert({top: '<div id="error" class="other-error">An error occurred. Please refresh your page.</div>'});
    return false;
  })
  .observe('ajax:after', function(evt, data, status, xhr){
    return false;
  })
})
