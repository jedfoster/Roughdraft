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


## Installation: Local ##

Redis is a pre-requisite. Skip the following steps if you already have Redis installed and running.

```
brew install redis  
redis-server
# verify Redis is running
redis-cli ping
```

If you want to start Redis on login, be sure to read the instructions `brew` gives after installation.

The app:

```
git clone https://github.com/jedfoster/Roughdraft.git
cd Roughdraft
mkdir tmp
touch tmp/restart.txt
```

Change the `APP_DOMAIN` constant in roughdraft.rb, line 68, to whatever local domain you want to use. I recommend using [Pow](http://pow.cx) for local development, especially on this project as the username subdomain feature doesn't work with IP addresses.

The GitHub API limits the number of unauthenticated requests to 60 per hour, which is too little for production and often even for development. To get around this you will need to [register your app with GitHub](https://github.com/settings/applications/new). Once you have your client ID and secret, rename config/github.example.yml to config/github.yml and paste in your app's credentials. Mine looks something like this:

```yaml
client_id: 9ef1xxxx
client_secret: 5784xxxxxxxx
```

You should now be able to submit up to 5000 requests per hour. 

**FAIR WARNING:** Your client ID and secret should _not_ be shared publicly. Do not commit github.yml to your repo, especially if you post your repo on GitHub. Read the instructions for configuring Heroku with your credentials, below.

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

Change the `APP_DOMAIN` constant in roughdraft.rb, line 41, to whatever custom domain your app will use.

The user subdomain feature doesn't seem to work without a custom domain name (i.e. *not* the Heroku generated domain.) This may be fixed in a future release. See [this article](https://devcenter.heroku.com/articles/custom-domains) on custom domain names and Heroku.

### GitHub authentication on Heroku ###

Since the YAML file with your API credentials is not committed to your repo, it won't be sent to Heroku, so we need another way of storing that information. Enter Heroku environment variables:

```
heroku config:set GITHUB_ID=9ef1xxxx
heroku config:set GITHUB_SECRET=5784xxxxxxxx
heroku open
# Rock and Roll, again.
```


