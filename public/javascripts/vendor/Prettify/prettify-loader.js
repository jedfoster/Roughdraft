pretty = function() {
  // Add pretty print to all pre and code tags.
  $('pre, code').addClass("prettyprint");

  // Remove prettify from code tags inside pre tags.
  $('pre code').removeClass("prettyprint");

  $('.prettyprint').addClass(function () {
    return 'lang-' + $(this).attr('lang');
  });

  // Activate pretty presentation.
  prettyPrint();
}