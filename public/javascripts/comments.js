(function($) {
  $('.content').append('<a href="#" id="comment-button">Comments</a>');

  $('#comment-button').on('click', function(event) {
    event.preventDefault();

    $.getJSON(window.location.pathname + '/comments.json', function(data) {
      console.log(data);

      var comments = document.createElement('ul');
      comments.setAttribute('id', 'comments');

      $(data).each(function() {
        $(comments).append('<li class="comment">\
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

      $('#comment-button').replaceWith(comments);
      
      pretty();
    });

    
  });

})(jQuery);