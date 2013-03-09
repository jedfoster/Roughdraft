Sometimes you have something to say that won't fit on Twitter, but is too small to justify a Tumblr. Enter Roughdraft.  

### How it works

1. [Create a public Gist][gh] on Github with one or more [Markdown][df] files.
2. Note the Gist ID number. It’s usually a longish number like `12345678`.
3. View your writing presented nicely at roughdraft.dev/*gist-id*

<p>Alternatively, you can drag this <a href="javascript:(function(e,a,g,h,f,c,b,d){if(!(f=e.jQuery)||g>f.fn.jquery||h(f)){c=a.createElement('script');c.type='text/javascript';c.src='http://ajax.googleapis.com/ajax/libs/jquery/'+g+'/jquery.min.js';c.onload=c.onreadystatechange=function(){if(!b&&(!(d=this.readyState)||d=='loaded'||d=='complete')){h((f=e.jQuery).noConflict(1),b=1);f(c).remove()}};a.documentElement.childNodes[0].appendChild(c)}})(window,document,'1.4.2',function($,L){var gist_re=/^https?\:\/\/gist\.github\.com\/(\d*)/i,rel_re=/^\/?(\d+)$/,on_gist=gist_re.test(location.href);if(on_gist){location.href='http://gist.io'+location.pathname;}else{$('a').each(function(){var b=$(this).attr('href')||'',a=b.match(gist_re);if(on_gist&&!(a&&a[1])){a=b.match(rel_re)}if(a&&a[1]){$(this).after(' <a href=&quot;http://gist.io/'+a[1]+'&quot;>[gist.io]</a>')}});}});" title="Roughdraft bookmarklet">bookmarklet</a> to your bookmarks bar. Click it when you’re on a Gist page, and it will take you to the corresponding Roughdraft page. Click it when you aren’t on a Gist page, and it will append Roughdraft links to every Gist link it finds on the page.</p>


### Content

Roughdraft currently only supports Markdown Gists, but will soon also support a limited number of other formats. Your Gist's *description* field will be used as the headline for your post. 


## Mad Props

This project is a deliberate and painstaking rip-off of [Idan Gazit's][gazit] [gist.io][gio], which is wonderful and you should check it out. I ported gist.io to Ruby both as a coding exercise and to build out some additional features I wanted. My thanks to Idan for his work on the original, which is very well done. You should follow him on [Twitter][igtw]. 




[gh]:     https://gist.github.com
[gio]:    http://gist.io
[df]:     http://daringfireball.net/projects/markdown/
[txtl]:   http://redcloth.org/hobix.com/textile/
[ex]:     http://gist.io/3135754
[issue]:  http://github.com/idan/gistio/issues
[idan]:   http://github.com/idan
[gazit]:  http://gazit.me
[igtw]:   http://twitter.com/idangazit
