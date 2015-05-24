pretty = function() {
  // Add pretty print to all pre and code tags.
  $('pre, code').addClass("prettyprint");

  // Remove prettify from code tags inside pre tags and from code or pre tags with class .no-prettify.
  $('pre code, .no-prettify').removeClass("prettyprint");

  $('.prettyprint').addClass(function () {
    return 'lang-' + $(this).attr('lang');
  });

  // Activate pretty presentation.
  prettyPrint();
}

pretty();