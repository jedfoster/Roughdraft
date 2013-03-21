require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'sinatra/partial'
require 'json'
require 'github_api'
require 'rack/request'
require 'sass'
require 'compass'
require 'yaml'
require 'html/pipeline'

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


configure do
  require 'redis'
  redisUri = ENV["REDISTOGO_URL"] || 'redis://localhost:6379'
  uri = URI.parse(redisUri)
  REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

configure :production do
  APP_DOMAIN = 'roughdraft.io'
  
  helpers do
    # def github(auth_token = '')
    #   github = Github.new do |config|
    #     config.client_id = ENV['GITHUB_ID']
    #     config.client_secret = ENV['GITHUB_SECRET']
    #     config.oauth_token = auth_token
    #   end
    # end
    
    def gh_config
      {
        client_id: ENV['GITHUB_ID'], 
        client_secret: ENV['GITHUB_SECRET']
      }
    end

    use Rack::Session::Cookie, #:key => 'example.com',
                               #:domain => 'example.com',
                               :path => '/',
                               :expire_after => 7776000, # 90 days, in seconds
                               :secret => ENV['COOKIE_SECRET']
  end
end

configure :development do
  APP_DOMAIN = 'roughdraft.dev'

  helpers do
    # def github(auth_token = '')
    #   gh_config = YAML.load_file("github.yml")
    # 
    #   github = Github.new do |config|
    #     config.client_id = gh_config['client_id']
    #     config.client_secret = gh_config['client_secret']
    #     config.oauth_token = auth_token
    #   end
    # end
    
    def gh_config
      YAML.load_file("github.yml")
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
    return false if language.nil?
    
    language.match(/(Markdown|Text)/)
  end

  def pipeline(html)
    context = {
      :asset_root => "http://#{APP_DOMAIN}/images",
      # :base_url   => "#{APP_DOMAIN}"
    }

    pipe = HTML::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      HTML::Pipeline::SanitizationFilter,
      HTML::Pipeline::ImageMaxWidthFilter,
      HTML::Pipeline::EmojiFilter
    ], context.merge(:gfm => true)

    pipe.call(html)[:output].to_s
  end

  def fetch_and_render_gist(id)
    begin
      gist = Github::Gists.new.get(id, client_id: gh_config['client_id'], client_secret: gh_config['client_secret'])

      gist.files.each do |file, value|
        if is_allowed value.language.to_s
          value[:rendered] = pipeline value.content.to_s
        end
      end
    
      REDIS.setex(id, 60, gist.to_hash.to_json.to_s)
      gist.to_hash.to_json.to_s
    
    rescue Github::Error::NotFound
      false
    end
  end

  def fetch_and_render_user(user_id)
    user = Github::Users.new.get(user: user_id, client_id: gh_config['client_id'], client_secret: gh_config['client_secret'])
    # from_redis = 'False'

    gists = Array.new

    Github::Gists.new.list(user: user['login'], client_id: gh_config['client_id'], client_secret: gh_config['client_secret']).each do |gist|
      gist.files.each do |key, file|
        if is_allowed file.language.to_s
          gists << gist.to_hash
          break
        end
      end
    end

    REDIS.setex(user['login'], 60, user.to_hash.merge({:gists => gists}).to_json)

    user = REDIS.get(user['login'])
  end
end


before do
  # @github = github()
  
  @user = @gist = false
end

before :subdomain => 1 do
  user = REDIS.get(request.subdomains[0])

  if ! user
    user = fetch_and_render_user(request.subdomains[0])
  end
  
  @user = JSON.parse(user) if request.subdomains[0] != 'www'
end


get '/' do
  if @user
    erb :list, :locals => {:user => @user}
  else
    erb :index
  end  
end


get %r{/([\d]+)$} do
  id = params[:captures].first
  valid = true

  content = REDIS.get(id)
  from_redis = 'True'

  if ! content
    from_redis = 'False'
    content = fetch_and_render_gist(id)
  end

  if @user
    valid = false

    @user['gists'].each do |gist|
      if gist['id'] == id
        valid = true
        break        
      end
    end
  end

  if valid && content
    headers 'X-Cache-Hit' => from_redis    

    @gist = JSON.parse(content)

    erb :gist
  else
    if content
      redirect to("http://#{JSON.parse(content)['owner']['login']}.#{APP_DOMAIN}/#{id}")
    else
      erb :invalid_gist, :locals => { :gist_id => id }
    end
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
