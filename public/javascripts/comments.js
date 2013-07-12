(function($) {
  if( ! window.location.pathname.match(/\/(new|edit)/) ) {
    $.ajax({
      dataType: "json",
      url: window.location.pathname + '/comments.json',
      success: function(data) {

        var author = window.location.host.split('.').shift();

        var comments = document.createElement('ul');
        comments.style.display = 'none';

        $(data).each(function() {
          $(comments).append('<li class="comment' + ((author == this.user.login) ? ' author-comment' : '' ) + '">\
            <h3>\
              <a href="https://github.com/' + this.user.login + '" class="login">' + this.user.login + '</a>\
              <time datetime="' + this.created_at + '">' + this.created_at_formatted + '</time>\
            </h3>\
            <div class="body">\
              ' + this.body_rendered + '\
            </div>\
          </li>');
        });

        $('.content').append('<footer id="comments"><h2 id="toggle-comments">Comments</h2></footer>');

        $('#comments').append(comments);

        $('#toggle-comments').on('click', function(event) {
          $('#comments ul').toggle();
        });

        pretty();
      },
      error: function(data) {
        // Do nothing
      }
    });
  }
})(jQuery);