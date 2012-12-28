// Extend prototype element methods
// http://www.prototypejs.org/api/element/addMethods
// load by issuing 'Element.addMethods(myElementMethods);'
// Usage (insert into erb file): 
// <% content_for :head do %>
//	<%= stylesheet_link_tag 'window', :media => 'screen' %>
//	<%= javascript_include_tag 'prototype' %>
// <% end %>
// <%= link_to_function 'Test', "showIndicator('#{image_path('indicator.gif')}')" %>
var myElementMethods = {
  setToCenter: function(element) {
    element = $(element);
    _left = document.viewport.getScrollOffsets()[0]+document.viewport.getWidth()/2+'px';
    _top = document.viewport.getScrollOffsets()[1]+document.viewport.getHeight()/2-100+'px';
    $(element).setStyle({position:'absolute',left:_left,top:_top});
    return element;
  },
  setToOverlay: function(element) {
    element = $(element);
    $(element).setStyle({position:'absolute',top:'0',left:'0',width:document.documentElement.getWidth()+'px',height:document.documentElement.getHeight()+'px'});
    return element;
  }
}
// Load custom prototype element methods

Element.addMethods(myElementMethods);

// show results indicator
// requires loading of prototype javascript library
function showIndicatorOverDiv(div_id) {
  image_path = '/images/indicator-small.gif';
  // Element.scrollTo($(document));
  Effect.ScrollTo('top');
  show_id = 'indicator';
  if (!$(show_id)) {
    $(document.body).insert("<div id='"+show_id+"'><image src=\""+image_path+"\" /></div>");
  }
  $(show_id).setToCenter();
  _left = $(div_id).cumulativeOffset().left + ($(div_id).getWidth() - $(show_id).getWidth())/2 + 'px';
  _top = $(div_id).cumulativeOffset().top + 20 +'px';
  $(show_id).setStyle({position:'absolute',left:_left,top:_top});
  $(div_id).setOpacity(0.2);
  $(show_id).show();
}
function hideIndicatorOverDiv(div_id) {
  show_id = 'indicator';
  if ($(show_id)) {
    $(show_id).hide();
  }
  if ($(div_id)) {
    $(div_id).setOpacity(1);
  }
}
// show screen and indicator
// requires loading of prototype javascript library
function showIndicator(image_path) {
  overlay_id = 'screen';
  show_id = 'indicator';
  if (!$(overlay_id)) {
    $(document.body).insert("<div id='"+overlay_id+"'></div>");
  }
  if (!$(show_id)) {
    $(document.body).insert("<div id='"+show_id+"'><image src=\""+image_path+"\" /></div>");
  }
  $(show_id).setToCenter();
  _left = $('results').cumulativeOffset + $(show_id)/2 + 'px';
  $(show_id).setStyle({left: _left});
  $(overlay_id).setToOverlay();
  $(overlay_id).setOpacity(0.3);
  $(overlay_id).show();
  $(show_id).show();
}
// hide screen and indicator
function hideIndicator() {
  overlay_id = 'screen';
  show_id = 'indicator';
  if ($(show_id)) {
    $(show_id).hide();
  }
  if ($(overlay_id)) {
    $(overlay_id).hide();
  }
}

// Clear given text input field if it contains specified text
// --------------------------------------------------
function clear_value(field, val) {
  if (field.value == val) {
    field.value = '';
  }
}

// Reset given text input field to specified text if blank
// --------------------------------------------------
function reset_value(field, val) {
  if (field.value == '') {
    field.value = val;
  }
}

// Reset all text input fields in given html form
// --------------------------------------------------
function clearForm(form) {
	Form.getInputs(form, 'text').each(function(input) {
		input.value = ''
	})
}

// Popup window for image enlargements
// --------------------------------------------------
function popupWindow(url) {
	window.open(url, 'popupWindow', 'toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=yes,copyhistory=no,width=100,height=100,screenX=150,screenY=150,top=150,left=150')
}

// Popup window for scribd documents
// --------------------------------------------------
function popupScribd(url) {   window.open(url,"reader","width="+900+",height="+700+",scrollbars=yes,resizable=yes,toolbar=no,directories=no,menubar=no,status=no,left=100,top=100");
  return false;
}

// Ajax cart message
// --------------------------------------------------
function showCartMessage(type, message) {
	scroll(0,0)
	Element.hide("cart");
	$("cart").className = type;
	Element.update("cart", message);
	new Effect.Appear("cart",{});
	new Effect.Fade("cart",{delay:5, queue:'end'});
}

// For slider
// --------------------------------------------------
function numberWithDelimiter(num, delimiter){
  num = num.toString();
  for (var i = 0; i < Math.floor((num.length-(1+i))/3); i++)
  num = num.substring(0,num.length-(4*i+3))+delimiter+num.substring(num.length-(4*i+3));
  return num;
}
