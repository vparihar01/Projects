/* Blinder Script
 * Based on Simple Accordion Script (see attribution below)
 * Notes:
 * 
 * 
 * 
 * 
 
 * Simple Accordion Script
 * Requires Prototype and Script.aculo.us Libraries
 * By: Brian Crescimanno <brian.crescimanno@gmail.com>
 * http://briancrescimanno.com
 * This work is licensed under the Creative Commons Attribution-Share Alike 3.0
 * http://creativecommons.org/licenses/by-sa/3.0/us/
 */

if (typeof Effect == 'undefined')
  throw("You must have the script.aculo.us library to use blinder.js");

var Blinder = Class.create({

    initialize: function(id) {
        if(!$(id)) throw("Attempted to initalize blinder with id: "+ id + " which was not found.");
        this.blinder = $(id);
        this.options = {
            toggleClass: "blinder-toggle",
            activeClass: "blinder-toggle-active",
            contentClass: "blinder-content"
        }
        this.contents = this.blinder.select('div.'+this.options.contentClass);
        this.isAnimating = false;
        this.setCurrent();
        this.toToggle = null;

        var clickHandler =  this.clickHandler.bindAsEventListener(this);
        this.blinder.observe('click', clickHandler);
    },

    toggle: function(el) {
      this.toToggle = el.next('div.'+this.options.contentClass);
      this.animate();
    },

    clickHandler: function(e) {
      var el = e.element();
      if(el.hasClassName(this.options.toggleClass) && !this.isAnimating) {
        this.toggle(el);
        Event.stop(e);
      }
    },
    
    setCurrent: function(){
      this.current = null
      
      actives = this.blinder.select('a.'+this.options.activeClass);
      if(actives.length == 1) this.current = actives[0];
      if(actives.length > 1) throw("More than one element with class '" + activeClass + "' found.");
      
      if(this.current == null) {
        for(var i=0; i<this.contents.length; i++){
          if(this.contents[i].visible()) {
            this.current = this.contents[i];
            break;
          }
        }
      }
    },

    animate: function() {
      this.isAnimating = true;
      new Effect.toggle(this.toToggle, 'blind', {duration:'0.2', queue:'front'});
      if(this.current != null && this.current != this.toToggle) {
        new Effect.BlindUp(this.current, {duration:'0.2', queue:'front'});
        this.current.previous('a.'+this.options.toggleClass).removeClassName(this.options.activeClass);
      }
      this.toToggle.previous('a.'+this.options.toggleClass).addClassName(this.options.activeClass);
      this.current = this.toToggle;
      this.isAnimating = false;
    }

});

document.observe("dom:loaded", function(){
  blinder = new Blinder("blinder-submenu");
})