var Tooltip = Class.create({
  initialize: function(element) {
    this.element = $(element);
    this.record_id = this.element.identify().match(/[0-9]+$/)[0];
    // indexOf does not work with IE6
    if (this.element.className.split(' ').indexOf('x') != -1) {
      this.url = "/products/"+this.record_id+"/tooltipx";
    } else {
      this.url = "/products/"+this.record_id+"/tooltip";
    }
    this.container = $('tooltip');
    this.initDOMReferences();
    this.initEventHandlers();
  }, // initialize

  initDOMReferences: function() {
    if (!this.container) {
      var my_div = document.createElement('div');
      my_div.setAttribute('id', 'tooltip');
      Element.extend(my_div);
      my_div.hide();
      document.body.appendChild(my_div);
      this.container = my_div;
    }
  }, // initDOMReferences

  initEventHandlers: function() {
    this.element.observe('mouseover', this.handleTooltipOver.bind(this));
    this.element.observe('mouseout', this.handleTooltipOut.bind(this));
  }, // initEventHandlers

  handleTooltipOver: function(e) {
    if (!bubbledFromChild(this.element,e)) {
      var element = this.element;
      var container = this.container;
      var record_id = this.record_id;
      var url = this.url;
      if (container.down("#product-"+record_id)) {
        new Effect.Appear(container, {queue: 'end', duration: 0.2})
      } else {
        if (Ajax.activeRequestCount == 0) {
          new Ajax.Request(url, {
            method: 'get',
            onLoading: function() {
              width = element.getWidth();
              container.clonePosition(element, {offsetLeft:width-3,offsetTop:-3,setWidth:false,setHeight:false});
              container.update('<div class="content"><p style="text-align:center;margin:10px;"><img src="/images/indicator.gif"</p></div>');
              new Effect.Appear(container, {queue: 'end', duration: 0.3});
            },
            onSuccess: function(xhr) {
              container.update(xhr.responseText);
          }});
        }
      }
    }
  }, // handleTooltipOver

  handleTooltipOut: function(e) {
    if (!bubbledFromChild(this.element,e)) {
      this.container.hide();
    }
  } // handleTooltipOut
  
}); // Tooltip

// from http://groups.google.com/group/prototype-scriptaculous/browse_thread/thread/badf3974a0dd5ac6
function bubbledFromChild(element, event) {
  var target = $(event).element();
  // if (target === element) target = event.relatedTarget;  # TIM: this was causing erratic behavior
  return (event.relatedTarget && event.relatedTarget.descendantOf(element));
};

document.observe('dom:loaded', function() {
  $$('.tipper').each(function(element) { new Tooltip(element); });
});
