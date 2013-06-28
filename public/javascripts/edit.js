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
          title = $('#general_text').outerHeight(),
          form_margin = parseInt($('.content.gist-edit').css('padding-top')) +
                        parseInt($('.content.gist-edit').css('padding-bottom')) +
                        parseInt($('.content.gist-edit').css('margin-top')) +
                        parseInt($('.content.gist-edit').css('margin-bottom')) +
                        parseInt($('.edit_container').css('margin-bottom'))  +
                        parseInt($('footer p').css('margin-bottom')) +
                        70,
          body_padding = parseInt($('body').css('padding-bottom')),
          footer = $("footer p").outerHeight();

      $('.edit_container').css('height', html - form_margin - title - footer + 2 - body_padding);
    }

    else {
      $('.edit_container').css('height', 482);
    }
  }

  $(window).resize(setHeight);
  setHeight();

  $('form .pre_container').each(function() {
    editors[$(this).data('filename')] = ace.edit($(this).attr('id'));
    editors[$(this).data('filename')].setTheme("ace/theme/tomorrow");
    editors[$(this).data('filename')].getSession().setMode("ace/mode/markdown");
    editors[$(this).data('filename')].getSession().setUseWrapMode(true);
    editors[$(this).data('filename')].getSession().setWrapLimitRange();

    var timer;
    editors[$(this).data('filename')].getSession().on('change', function(e) {
      clearTimeout(timer);
      // timer = setTimeout(function() {$("form").submit();}, 750);
    });
  });

  var buildModal = function(content) {
    if ($('#modal').length == 0) {
      $('body').append('<div class="reveal-modal large" id="modal"><span class="reveal-close"><a href="#" class="close-icon">Close Preview</a></span><span class="reveal-content">' + content + '</span></div>');
    }
    else {
      $('#modal .reveal-content').empty();
      $('#modal .reveal-content').append(content);
    }

    $('#modal').reveal({
      animation: 'fadeAndPop', //fade, fadeAndPop, none
      animationSpeed: 200, //how fast animations are
      closeOnBackgroundClick: true, //if you click background will modal close?
      dismissModalClass: 'close-icon' //the class of a button or element that will close an open modal
    });

    $('.reveal-modal-bg').css('height', $("html").outerHeight());
    $('#modal').css('height', 'auto');
  }

  /* attach a submit handler to the form */
  $("form").submit(function(event) {
    event.preventDefault();
    $('#save-edit').addClass('pulse');

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
        
        $('#save-edit').removeClass('pulse');
      }
    );

   //localStorage.setItem('inputs', JSON.stringify(inputs));
  });

  $('#preview-edit').on('click', function() {
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
    $.post($(this).attr('href'), inputs,
      function( data ) {
        var description = '<header><h1>' + data.description + '</h1></header>';

        var files = '';

        $(data.files).each(function(key, value) {
          files = files + '<article class="file">' +  value + '</article>'
        });

        buildModal('<section class="content">' + description + files + '</section>')
      }
    );
  });

  $('#save-edit').on('click', function() {
    console.log('button click');
    $("form").submit();
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