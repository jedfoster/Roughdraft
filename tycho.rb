# Those little ditties that Sinara needs to make the magic happen
# -----------------------------------------------------------------------
require 'rubygems'

# If you're using bundler, you will need to add this
require 'bundler/setup'

require 'sinatra'
require 'sinatra/partial'
require 'json'
require 'github_api'

require 'rack/request'

require 'sass'
require 'compass'
require 'yaml'
require 'github/markdown'

require 'redcarpet'
require 'RedCloth'


module Rack
  class Request
    def subdomains(tld_len=1) # we set tld_len to 1, use 2 for co.uk or similar
      # cache the result so we only compute it once.
      @env['rack.env.subdomains'] ||= lambda {
        # check if the current host is an IP address, if so return an empty array
        return [] if (host.nil? ||
                      /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.match(host))
        host.split('.')[0...(1 - tld_len - 2)] # pull everything except the TLD
      }.call
    end
  end
end


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
        value[:rendered] = GitHub::Markdown.render_gfm(value.content.to_s)
      end
    end
    
    REDIS.setex(id, 60, gist.to_hash.to_json.to_s)
    gist.to_hash.to_json.to_s
  end
end

before do
  @github = github(session[:github_token])
end


set(:subdomain) { |number_of_subdomains| condition { request.subdomains.count == number_of_subdomains } }

get '/', :subdomain => 1 do
  user = REDIS.get(request.subdomains[0])

  if ! user
    user = @github.users.get(user: request.subdomains[0])

    gists = Array.new

    @github.gists.list(user: user['login']).each do |value|
      gists << value.to_hash
    end

    REDIS.setex(user['login'], 60, user.to_hash.merge({:gists => gists}).to_json)

    user = REDIS.get(user['login'])
  end

  erb :list, :locals => {:user => JSON.parse(user)}  
end


get '/' do
  erb :index
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
