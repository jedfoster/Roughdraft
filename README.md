Roughdraft
=====

A Ruby implementation of [Gist.io](https://github.com/idan/gistio) built with Sinatra.


## Usage ##

View a gist at roughdraft.dev/*gist-id*. Example: [roughdraft.dev/4370358](roughdraft.dev/4370358)

View a list of a GitHub user's Gists at *username*.roughdraft.dev. Example [jedfoster.roughdraft.dev](jedfoster.roughdraft.dev). Only **public** Gists with renderable content are listed. 

If you happen to be on a user subdomain, e.g. jedfoster.roughdraft.dev, and you paste in a Gist ID that does not belong to that user, you will be redirected to the appropriate subdomain. Example: [jedfoster.roughdraft.dev/4731881](jedfoster.roughdraft.dev/4731881) will redirect to [blackfalcon.roughdraft.dev](blackfalcon.roughdraft.dev), because `jedfoster` does not own that Gist.

Roughdraft supports [GitHub Flavored Markdown](https://help.github.com/articles/github-flavored-markdown), including fenced code blocks with syntax highlighting. Example:


<pre><code>```ruby
require 'redcarpet'
markdown = Redcarpet.new("Hello World!")
puts markdown.to_html
```</code></pre>


## To Do ##

- [ ] investigate [HTML::Pipeline](https://github.com/jch/html-pipeline) for rendering
- [ ] fix bookmarklet, `:user/:id` should forward to `:user.APP_DOMAIN/:id`
- [ ] method for user index page copy, a specially marked up Gist?
- [ ] GitHub authentication, to get around API rate limit
- [ ] Unrenderable files should be shown as links


## Installation: Local ##

Redis is a pre-requisite. Skip the following steps if you already have Redis installed and running.

````
brew install redis  
redis-server
# verify Redis is running
redis-cli ping
````

If you want to start Redis on login, be sure to read the instructions `brew` gives after installation.

The app:

````
git clone https://github.com/jedfoster/Roughdraft.git
cd Roughdraft
mkdir tmp
touch tmp/restart.txt
````

Change the `APP_DOMAIN` constant in roughdraft.rb, line 68, to whatever local domain you want to use. I recommend using [Pow](http://pow.cx) for local development, especially on this project as the username subdomain feature doesn't work with IP addresses.

````
# Restart Pow
touch tmp/restart.txt
# Rock and Roll
````

## Installation: Heroku ##

````
heroku create
heroku addons:add redistogo
git push heroku
heroku open
# Rock and Roll
````

The user subdomain feature doesn't seem to work without a custom domain name (i.e. *not* the Heroku generated domain.) This may be fixed in a future release. See [this article](https://devcenter.heroku.com/articles/custom-domains) on custom domain names and Heroku.

