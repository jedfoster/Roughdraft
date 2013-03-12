(function($) {
  function positionBookmarklet() {
    if($('#bookmarklet').css("position") == 'absolute') {
      var offset = $('#bookmarklet_steps').position().top;
      console.log($('#bookmarklet_steps').position().top);
      $('#bookmarklet').offset({top: offset});
    }
  }
  
  positionBookmarklet();
  
  $(window).resize(positionBookmarklet);
})(jQuery);