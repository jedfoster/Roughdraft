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
    
    console.log($(this).attr('href'));
    
    $.getJSON($(this).attr('href') + '.json', function( data ) {
      var items = [];

      $.each(data.list, function(key, val) {
        items.push('<li><a href="/' + val.id + '">' + ( val.description ? val.description : val.id ) + '</a><span class="posted">posted: <time datetime="' + val.created_at + '">' + val.created_at_rendered + '</time></span></li>');
      });

      $('#list').html(items.join(''));

      if(data.links.prev > 0) {
        $('#list-nav a.prev-link').attr('href', '/page/' + data.links.prev).show();
      }
      else {
        $('#list-nav a.prev-link').hide()
      }
      
      if(data.links.next > 0) {
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

