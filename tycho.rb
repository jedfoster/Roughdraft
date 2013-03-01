# Those little ditties that Sinara needs to make the magic happen
# -----------------------------------------------------------------------
require 'rubygems'

# If you're using bundler, you will need to add this
require 'bundler/setup'

require 'sinatra'
require 'sinatra/partial'
require 'json'
require 'github_api'

require 'sass'
require 'compass'
require 'yaml'
require 'github/markup'

require 'redcarpet'
require 'RedCloth'


set :partial_template_engine, :erb

# enable :sessions

configure do
  require 'redis'
  redisUri = ENV["REDISTOGO_URL"] || 'redis://localhost:6379'
  uri = URI.parse(redisUri)
  REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

configure :production do
  helpers do
    def github(auth_token = '')
      github = Github.new do |config|
        config.client_id = ENV['GITHUB_ID']
        config.client_secret = ENV['GITHUB_SECRET']
        config.oauth_token = auth_token
      end
    end

    use Rack::Session::Cookie, #:key => 'example.com',
                               #:domain => 'example.com',
                               :path => '/',
                               :expire_after => 7776000, # 90 days, in seconds
                               :secret => ENV['COOKIE_SECRET']
  end
end

configure :development do
  helpers do
    def github(auth_token = '')
      gh_config = YAML.load_file("github.yml")

      github = Github.new do |config|
        config.client_id = gh_config['client_id']
        config.client_secret = gh_config['client_secret']
        config.oauth_token = auth_token
      end
    end

    use Rack::Session::Cookie, #:key => 'example.dev',
                               :path => '/',
                               :expire_after => 7776000, # 90 days, in seconds
                               :secret => 'local'
  end
end


helpers do
  include ERB::Util
  alias_method :code, :html_escape

  # From: http://rubyquicktips.com/post/2625525454/random-array-item
  class Array
    def random
      shuffle.first
    end


    def to_sentence
      length < 2 ? first.to_s : "#{self[0..-2] * ', '}, and #{last}"
    end
  end

  def is_allowed(language)
    language.match(/(Markdown|Text|Textile)/)
  end

  def fetch_and_render(id)
    gist = @github.gists.get(id)

    gist.files.each do |file, value|
      if is_allowed value.language
        value[:rendered] = GitHub::Markup.render(file, value.content.to_s)
      end
    end
    
    REDIS.setex(id, 60, gist.to_hash.to_json.to_s)
    gist.to_hash.to_json.to_s
  end
end

before do
  @github = github(session[:github_token])
end


get '/' do
  erb GitHub::Markup.render('index.md', File.read('views/index.md')), :locals => { :gist_id => false }
end


get '/authorize' do
  redirect to @github.authorize_url :scope => ['gist', 'user']
end


get '/authorize/return' do
  token = Github.get_token(params[:code])

  user = github(token.token).users.get

  session[:github_token] = token.token
  session[:github_id] = user.login
  session[:gravatar_id] = user.gravatar_id

  redirect to('/')
end


get '/logout' do
  session[:github_token] = nil
  session[:github_id] = nil
  session[:gravatar_id] = nil

  redirect to('/')
end


get %r{/([\d]+)$} do
  erb :gist, :locals => { :gist_id => params[:captures].first }
end


get %r{/([\d]+)/content} do
  id = params[:captures].first

  content = REDIS.get(id)
  from_redis = 'True'

  if ! content
    from_redis = 'False'
    content = fetch_and_render(id)
  end

  headers 'Content-Type' => "application/json;charset=utf-8",
    'Cache-Control' => "private, max-age=0, must-revalidate",
    'X-Cache-Hit' => from_redis,
    'X-Expire-TTL-Seconds' => REDIS.ttl(id).to_s

  content
end
