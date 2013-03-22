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