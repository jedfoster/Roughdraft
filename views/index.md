## About gist.io

There's a scale of permanence to writing on the web. On one end, we have the tweet: brief and ephemeral. On the other end of the scale, we have longform blog writing: unlimited in length and hopefully impervious to the passage of time.

Sometimes, we just want to share a bit of writing that is neither. Maybe we want to write for a specific audience, but don’t want to address the people who usually read our blogs. Maybe it’s just something that doesn’t fit into 140 characters.

For these situations, even setting up a Tumblr seems like too much effort. Pastebins are great, but the reading experience sucks in general, and particularly on mobile devices.

Gist.io is a solution for that, inspired by Mike Bostock’s delightful [bl.ocks.org][block].

### Usage

1. [Create a public gist][gh] on Github with one or more [Markdown][df]-syntax files.
2. Note the gist ID number. It’s usually a longish number like `29388372`.
3. View your writing presented nicely at gist.io/*gist-id-here*


<p>Be lazy like me and drag the <a href="javascript:(function(e,a,g,h,f,c,b,d){if(!(f=e.jQuery)||g>f.fn.jquery||h(f)){c=a.createElement('script');c.type='text/javascript';c.src='http://ajax.googleapis.com/ajax/libs/jquery/'+g+'/jquery.min.js';c.onload=c.onreadystatechange=function(){if(!b&&(!(d=this.readyState)||d=='loaded'||d=='complete')){h((f=e.jQuery).noConflict(1),b=1);f(c).remove()}};a.documentElement.childNodes[0].appendChild(c)}})(window,document,'1.4.2',function($,L){var gist_re=/^https?\:\/\/gist\.github\.com\/(\d*)/i,rel_re=/^\/?(\d+)$/,on_gist=gist_re.test(location.href);if(on_gist){location.href='http://gist.io'+location.pathname;}else{$('a').each(function(){var b=$(this).attr('href')||'',a=b.match(gist_re);if(on_gist&&!(a&&a[1])){a=b.match(rel_re)}if(a&&a[1]){$(this).after(' <a href=&quot;http://gist.io/'+a[1]+'&quot;>[gist.io]</a>')}});}});" title="gist.io bookmarklet"><b>gist.io bookmarklet</b></a> to your bookmarks bar. Click it when you’re on a gist page, and it will take you to the corresponding gist.io page. Click it when you aren’t on a gist page, and it will append gist.io links to every gist link it finds on the page.</p>


### Content

Right now the service supports writing, and that's it. The gist's *description* field will be used as the title for your writing. You should structure your writing such that the highest-level heading is an H2, as the post title will be a first-level heading. Check out the [example post][ex] for more clues on what you can and should do when writing for gist.io. If you run into something broken, or your markup isn't rendering, [file a ticket][issue] with the gist id.

Happy writing!

Idan Gazit

[Web][gazit] / [Twitter][igtw] / [Github][idan]



[gh]:     https://gist.github.com
[gio]:    http://gist.io
[df]:     http://daringfireball.net/projects/markdown/
[txtl]:   http://redcloth.org/hobix.com/textile/
[ex]:     http://gist.io/3135754
[issue]:  http://github.com/idan/gistio/issues
[block]:  http://bl.ocks.org/
[idan]:   http://github.com/idan
[gazit]:  http://gazit.me
[igtw]:   http://twitter.com/idangazit
