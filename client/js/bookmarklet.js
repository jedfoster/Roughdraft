(function() {
  var gist_regex = /^https:\/\/gist\.github\.com\/([\w-]+)\/(\w+)*$/i,
      rel_regex = /^\/?(\d+)$/,
      on_gist = gist_regex.test(location.href);

  if(on_gist) {
    i = location.pathname.split(/\/([\w-]+)\/(\w+)/);
    location.href = 'http://' + i[1] + '.roughdraft.io/' + i[2];
  } 

  else {
    Array.prototype.forEach.call(document.querySelectorAll('a'), function(el){
      var b = el.getAttribute('href') || '',
          a = b.match(gist_regex);

      if (on_gist && !(a && a[2])) {
        a = b.match(rel_regex)
      }
      if (a && a[2]) {
        if(typeof(a[1]) == 'undefined') {
          a[1] = 'www';
        }

        el.insertAdjacentHTML('afterend', ' <a href=&quot;http://' + a[1] + '.roughdraft.io/' + a[2] + '&quot;>[roughdraft.io]</a>');
      }
    });
  }
})();
