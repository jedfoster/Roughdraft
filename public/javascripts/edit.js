/*
bindWithDelay jQuery plugin
Author: Brian Grinstead
MIT license: http://www.opensource.org/licenses/mit-license.php

http://github.com/bgrins/bindWithDelay
*/
(function($) {
  $.fn.bindWithDelay = function( type, data, fn, timeout, throttle ) {
  	if ( $.isFunction( data ) ) {
  		throttle = timeout;
  		timeout = fn;
  		fn = data;
  		data = undefined;
  	}

  	// Allow delayed function to be removed with fn in unbind function
  	fn.guid = fn.guid || ($.guid && $.guid++);

  	// Bind each separately so that each element has its own delay
  	return this.each(function() {
      var wait = null;

      function cb() {
        var e = $.extend(true, { }, arguments[0]);
        var ctx = this;
        var throttler = function() {
        	wait = null;
        	fn.apply(ctx, [e]);
        };

        if (!throttle) { clearTimeout(wait); wait = null; }
        if (!wait) { wait = setTimeout(throttler, timeout); }
      }

      cb.guid = fn.guid;

      $(this).bind(type, data, cb);
  	});
  }
})(jQuery);
/* --- END bindWithDelay --- */


(function($) {
  var editors = {};
  
  
  function setHeight() {
    if ($("html").width() > 50 * 18) {
      var html = $("html").height(),
          // header = $(".site_header").height(),
          title = $('#general_text').outerHeight(),
          form_margin = parseInt($('.content.gist-edit').css('padding-top')) +
                        parseInt($('.content.gist-edit').css('padding-bottom')) +
                        parseInt($('.content.gist-edit').css('margin-top')) +
                        parseInt($('.content.gist-edit').css('margin-bottom')) +
                        parseInt($('.edit_container').css('margin-bottom'))  +
                        parseInt($('footer p').css('margin-bottom')) +
                        $('.content.gist-edit button').outerHeight()  + 26,          
          body_padding = parseInt($('body').css('padding-bottom')),
          footer = $("footer p").outerHeight();

      // $('.pre_container, .ace_scroller').css('height', html - form_margin - title - footer - body_padding);
      $('.edit_container').css('height', html - form_margin - title - footer + 2 - body_padding);
    }

    else {
      // $('.pre_container, .ace_scroller').css('height', 480);
      $('.edit_container').css('height', 482);
    }
  }

  $(window).resize(setHeight);
  setHeight();
  
  

  $('form .pre_container').each(function() {
    // console.log($(this).attr('id'));
    editors[$(this).data('filename')] = ace.edit($(this).attr('id'));
    editors[$(this).data('filename')].setTheme("ace/theme/tomorrow");
    editors[$(this).data('filename')].getSession().setMode("ace/mode/markdown");
    editors[$(this).data('filename')].getSession().setUseWrapMode(true);
    editors[$(this).data('filename')].getSession().setWrapLimitRange();


    var timer;
    editors[$(this).data('filename')].getSession().on('change', function(e) {
      clearTimeout(timer);
      timer = setTimeout(function() {$("form").submit();}, 750);
    });
  });




  //var timer;
  //editor.getSession().on('change', function(e) {
  //  clearTimeout(timer);
  //  timer = setTimeout(function() {$("form").submit();}, 750);
  //});
  //
  // console.log(editors);


  /* attach a submit handler to the form */
  $("form").submit(function(event) {
    event.preventDefault();

    var contents = {};

    for (var key in editors) {
      contents[key] = {'content': editors[key].getValue()};
    }

    // _gaq.push(['_trackEvent', 'Form', 'Submit']);

    var inputs = {
      contents: contents,
      title: $('#title').val(),
    }

    /* Post the form and handle the returned data */
    $.post($(this).attr('action'), inputs,
      function( data ) {
        console.log(data);
      }
    );

   //localStorage.setItem('inputs', JSON.stringify(inputs));
  });

  //if($('#gist-input').text().length > 0) {
  //  var storedInputs = JSON.parse($('#gist-input').text());
  //}
  //else {
  //  var storedInputs = JSON.parse(localStorage.getItem('inputs'));
  //}

  //if( storedInputs !== null) {
  //  sass.setValue(storedInputs.sass);
  //  sass.clearSelection();
  //  $('select[name="syntax"]').val(storedInputs.syntax).data('orignal', storedInputs.syntax);
  //  $('select[name="plugin"]').val(storedInputs.plugin);
  //  $('select[name="output"]').val(storedInputs.output);
  //  $("#sass-form").submit();
  //}





  //$('#reset').on('click', function() {
  //  event.preventDefault();
  //
  //  $("#sass-form").get(0).reset();
  //  $('#gist-it').data('gist-save', '');
  //
  //  sass.setValue('');
  //  css.setValue('');
  //
  //  $.post('/reset');
  //
  //  var myNewState = {
  //  	data: { },
  //  	title: 'SassMeister | The Sass Playground!',
  //  	url: '/'
  //  };
  //  history.pushState(myNewState.data, myNewState.title, myNewState.url);
  //  window.onpopstate = function(event){
  //  	console.log(event.state); // will be our state data, so myNewState.data
  //  }
  //});
})(jQuery);