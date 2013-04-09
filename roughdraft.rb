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

require './lib/gist.rb'
require './lib/user.rb'
require './lib/gist_list.rb'

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

    module Roughdraft
      def self.gh_config
        YAML.load_file("github.yml")
      end
    end

    use Rack::Session::Cookie, #:key => 'example.dev',
                               :path => '/',
                               :expire_after => 7776000, # 90 days, in seconds
                               :secret => 'local'
  end
end


helpers do
  def is_allowed(language)
    return false if language.nil?

    language.match(/(Markdown|Text)/)
  end

  def fetch_gist_list(user_id, page = 1)
    gists = Array.new

    g = Github::Gists.new.list(user: user_id, client_id: Roughdraft.gh_config['client_id'], client_secret: Roughdraft.gh_config['client_secret']).page(page)

    g.each do |gist|
      gist.files.each do |key, file|
        if is_allowed file.language.to_s
          gists << gist.to_hash
          break
        end
      end
    end

    REDIS.setex("gist-list: #{user_id}, pg: #{page}", 60, {
      :list => gists,
      :page_count => g.count_pages,
      :links => {
        :next => g.links.next ? g.links.next.scan(/&page=(\d)/).first.first : nil,
        :prev => g.links.prev ? g.links.prev.scan(/&page=(\d)/).first.first : nil,
      }
    }.to_json)

    gistList = REDIS.get("gist-list: #{user_id}, pg: #{page}")
  end
end


before do
  @user = @gist = false
end

before :subdomain => 1 do
  if request.subdomains[0] != 'www'
    @user = User.new(request.subdomains[0]).user
  end
end


get '/' do
  if @user
    gists = GistList.new(@user['login'])

    headers 'X-Cache-Hit' => gists.from_redis

    erb :list, :locals => {:user => @user, :gists => gists.list}
  else
    erb :index
  end
end


get '/page/:page' do
  if @user
    gists = GistList.new(@user['login'], params[:page])

    headers 'X-Cache-Hit' => gists.from_redis

    erb :list, :locals => {:user => @user, :gists => gists.list}
  else
    redirect '/'
  end
end


get %r{/([\d]+)$} do
  id = params[:captures].first
  valid = true

  @gist = Gist.new(id)

  if @user && @gist.content["owner"]["login"].to_s != @user["login"].to_s
    valid = false
  end

  if valid && @gist.content
    headers 'X-Cache-Hit' => @gist.from_redis

    @gist = @gist.content

    erb :gist
  else
    if @gist.content
      redirect to("http://#{@gist.content["owner"]["login"].to_s}.#{APP_DOMAIN}/#{id}")
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
