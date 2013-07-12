(function($) {
  $('.content').append('<footer id="comments"><h2 id="comment-button">Comments</h2></footer>');

  $('#comment-button').on('click', function(event) {
    event.preventDefault();

    var author = window.location.host.split('.').shift();

    $.getJSON(window.location.pathname + '/comments.json', function(data) {
      var comments = document.createElement('ul');

      $(data).each(function() {
        $(comments).append('<li class="comment' + ((author == this.user.login) ? ' author-comment' : '' ) + '">\
          <h3>\
            <a href="https://github.com/' + this.user.login + '" class="login">\
              ' + this.user.login + '\
            </a>\
            <time datetime="' + this.created_at + '">' + this.created_at_formatted + '</time>\
          </h3>\
          <div class="body">\
            ' + this.body_rendered + '\
          </div>\
        </li>');
      });

      var newButton = $('<h2 id="toggle-comments">Comments</h2>');

      $('#comment-button').replaceWith(newButton);
      $('#comments').append(comments);      
      
      $('#toggle-comments').on('click', function(event) {
        event.preventDefault();
        
        // if($('#comments').is(":visible")) {
        //   $('#toggle-comments').text('Hide comments');
        // }
        // else {
        //   $('#toggle-comments').text('Show comments');
        // }

        $('#comments ul').toggle();
      });
      
      pretty();
    });
  });

  

})(jQuery);