require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'sinatra/partial'
require 'json'
require 'github_api'
require 'rack/request'
# require 'sass'
# require 'compass'
require 'yaml'
require 'html/pipeline'

require './lib/gist.rb'
require './lib/user.rb'
require './lib/gist_list.rb'
require './lib/html/pipeline/gist.rb'

require 'sinatra/respond_to'

Sinatra::Application.register Sinatra::RespondTo

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

set(:subdomain) { |num_subdomains| condition { request.subdomains.count == num_subdomains } }

# ENV["DEBUG"] = "true"

configure do
  require 'redis'
  redisUri = ENV["REDISTOGO_URL"] || 'redis://localhost:6379'
  uri = URI.parse(redisUri)
  REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

configure :production do
  APP_DOMAIN = 'roughdraft.io'

  helpers do

    module Roughdraft
      def self.gh_config
        {
          "client_id" => ENV['GITHUB_ID'],
          "client_secret" => ENV['GITHUB_SECRET']
        }
      end
    end

    use Rack::Session::Cookie, :key => 'roughdraft.io',
                               :domain => 'roughdraft.io',
                               :path => '/',
                               :expire_after => 7776000, # 90 days, in seconds
                               :secret => ENV['COOKIE_SECRET']
  end
end

configure :development do
  APP_DOMAIN = 'roughdraft.dev'

  helpers do

    module Roughdraft
      def self.gh_config
        YAML.load_file("github.yml")
      end
    end

    use Rack::Session::Cookie, :key => 'roughdraft.dev',
                               :path => '/',
                               :expire_after => 7776000, # 90 days, in seconds
                               :secret => 'local'
  end
end


helpers do
  def github(auth_token = '')
    github = Github.new do |config|
      config.client_id = Roughdraft.gh_config['client_id']
      config.client_secret = Roughdraft.gh_config['client_secret']
      config.oauth_token = auth_token
    end
  end
end


before do
  @user = @gist = false
  @github = github(session[:github_token])
end

before :subdomain => 1 do
  if request.subdomains[0] != 'www'
    @user = User.new(request.subdomains[0])
  end
end


get '/' do
  if @user
    status, headers, body = call env.merge("PATH_INFO" => '/page/1')
    [status, headers, body]
  else
    erb :index
  end
end


get '/page/:page' do
  if @user
    gists = GistList.new(@user.id, params[:page])

    headers 'X-Cache-Hit' => gists.from_redis

    respond_to do |wants|
      wants.html { erb :list, :locals => {:gists => gists} }    # => views/comment.html.haml, also sets content_type to text/html
      wants.json { gists.listify.to_json } # => sets content_type to application/json
      # wants.js { erb :comment }       # => views/comment.js.erb, also sets content_type to application/javascript
    end

  else
    redirect '/'
  end
end


get %r{(?:/)?([\w-]+)?/([\d]+)$} do
  id = params[:captures].last
  valid = true

  @gist = Gist.new(id)

  if ! @gist.content
    @gist = false

    return erb :invalid_gist, :locals => { :gist_id => id }
  end

  @user = User.new(params[:captures].first) unless @user

  if request.url == @gist.roughdraft_url
    headers 'X-Cache-Hit' => @gist.from_redis

    erb :gist
  else
    redirect to(@gist.roughdraft_url)
  end
end


get %r{/([\d]+)/content} do
  id = params[:captures].first

  content = REDIS.get(id)
  from_redis = 'True'

  if ! content
    from_redis = 'False'
    content = fetch_and_render_gist(id)
  end

  headers 'Content-Type' => "application/json;charset=utf-8",
    'Cache-Control' => "private, max-age=0, must-revalidate",
    'X-Cache-Hit' => from_redis,
    'X-Expire-TTL-Seconds' => REDIS.ttl(id).to_s

  content
end


get '/authorize' do
  # return @github.inspect
  
  redirect to @github.authorize_url :scope => ['gist', 'user']
end


get '/authorize/return' do
  token = @github.get_token(params[:code])

  user = github(token.token).users.get

  session[:github_token] = token.token
  session[:github_id] = user.login
  session[:gravatar_id] = user.gravatar_id

  redirect to("http://#{user.login}.#{APP_DOMAIN}/")
end


get '/logout' do
  session[:github_token] = nil
  session[:github_id] = nil
  session[:gravatar_id] = nil

  redirect to('/')
end
