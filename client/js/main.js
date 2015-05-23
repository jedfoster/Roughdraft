(function($) {
  function positionBookmarklet() {
    if($('#roughdraft-bookmarklet').css("position") == 'absolute') {
      var offset = $('#bookmarklet_steps').position().top;
      console.log($('#bookmarklet_steps').position().top);
      $('#roughdraft-bookmarklet').offset({top: offset});
    }
  }

  positionBookmarklet();

  $(window).resize(positionBookmarklet);
})(jQuery);


(function($) {
  $('#list-nav a').on('click', function() {
    event.preventDefault();

    var edit = $(this).data('edit');

    $.getJSON($(this).attr('href') + '.json', function( data ) {
      var items = [];

      $.each(data.list, function(key, val) {
        items.push('<li><a href="/' + val.id + '">' + ( val.description ? val.description : val.id ) + '</a><span class="posted">posted: <time datetime="' + val.created_at + '">' + val.created_at_rendered + '</time></span>' + ( edit ? '<a href="/' + val.id + '/edit" class="edit">Edit</a> <a href="/' + val.id + '/delete.json" class="button delete" data-confirm="Are you sure you want to delete \'' + ( val.description ? val.description : val.id ) + '\'? THERE IS NO UNDO!" data-method="delete" data-remote="true">Delete</a>' : '' ) + '</li>');
      });

      $('#list').html(items.join(''));

      if(data.links.prev) {
        if($('#list-nav a.prev-link').length == 0) {
          $('#list-nav').prepend('<a href="" class="prev-link">Newer</a>');
        }

        $('#list-nav a.prev-link').attr('href', '/page/' + data.links.prev).show();
      }
      else {
        $('#list-nav a.prev-link').hide()
      }

      if(data.links.next) {
        if($('#list-nav a.next-link').length == 0) {
          $('#list-nav').append('<a href="" class="next-link">Older</a>');
        }

        $('#list-nav a.next-link').attr('href', '/page/' + data.links.next).show();
      }
      else {
        $('#list-nav a.next-link').hide()
      }
    });

    var myNewState = {
    	data: { },
    	title: 'Roughdraft | Gist-powered writing.',
    	url: $(this).attr('href')
    };
    history.pushState(myNewState.data, myNewState.title, myNewState.url);
    window.onpopstate = function(event){
    	console.log(event.state); // will be our state data, so myNewState.data
    }
  });
})(jQuery);

