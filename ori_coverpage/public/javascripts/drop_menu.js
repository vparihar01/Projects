var MenuToggler = Class.create({
  initialize: function(element) {
    this.element = $(element); 
    this.initDOMReferences();
    this.initEventHandlers();
  }, // initialize    

  initDOMReferences: function() {
    var togglers = this.element.descendants().findAll(function(elt) { 
      return elt.hasClassName('toggler');
    });      
    if (!togglers) {
      console.log('Menu must have links with toggler class.');
      throw 'Menu must have links with toggler class.';
    }
    togglers.each(function(e) { 
      e._isToggler = 1;
      heading = e.up('LI');
      //console.log('heading = ' + heading.inspect());
      if (!heading) {
        console.log('Toggler must have heading.');
        throw 'Toggler must have heading.';
      }
      e.heading = heading;
      submenu = e.up('LI').down('UL');
      //console.log('submenu = ' + submenu.inspect());
      if (!submenu) {
        console.log('Toggler must have submenu.');
        throw 'Toggler must have submenu.';
      }
      e.submenu = submenu;
    });
  }, // initDOMReferences

  initEventHandlers: function() {
    this.handler = this.handleTogglerClick.bind(this); 
    this.element.observe('click', this.handler);
  }, // initEventHandlers

  handleTogglerClick: function(e) {
    var element = e.element();
    if (!('_isToggler' in element)) {
      element = element.ancestors().find(function(elt) { 
        return '_isToggler' in elt;
      });
      if (!((element) && '_isToggler' in element))
        return;
    }
    hideOtherSubmenus(element);
    element.heading.toggleClassName('selected');   
    element.submenu.toggle();
    Event.stop(e);
  } // handleTogglerClick   
  
}); // MenuToggler

hideOtherSubmenus = function(element) {
  var otherTogglers = $$('.toggler').findAll(function(elt) { 
    return '_isToggler' in elt && elt != element;
  });
  otherTogglers.each(function(elt) {
    elt.heading.removeClassName('selected');   
    elt.submenu.hide();
  });
}

document.observe('dom:loaded', function() {
  $$('ul.nav').each(function(menu) { new MenuToggler(menu); });
});

document.observe('click', function() {
  hideOtherSubmenus();
});
