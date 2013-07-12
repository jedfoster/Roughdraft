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
require './lib/gist_comments.rb'
require './lib/html/pipeline/gist.rb'
require './lib/roughdraft.rb'

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
                               :domain => '.roughdraft.io',
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
        YAML.load_file("config/github.yml")
      end
    end

    use Rack::Session::Cookie, :key => 'roughdraft.dev',
                               :domain => '.roughdraft.dev',
                               :path => '/',
                               :expire_after => 7776000, # 90 days, in seconds
                               :secret => 'local'
  end
end


helpers do
  include ERB::Util
  alias_method :code, :html_escape

  include Roughdraft

  def _params
    params
  end
end


before do
  @user = @gist = @action = false
  @github = Roughdraft.github(session[:github_token])
end

before :subdomain => 1 do
  if request.subdomains[0] != 'www'
    @user = User.new(request.subdomains[0])
  end
end


get %r{^(/|/feed)$}, :provides => ['html', 'json', 'xml'] do
  @action = 'home'

  if @user
    status, headers, body = call env.merge("PATH_INFO" => '/page/1')
    [status, headers, body]
  else
    erb :index
  end
end


get '/page/:page' do
  @action = 'list'

  if @user
    gists = GistList.new(@user.id, params[:page])

    headers 'X-Cache-Hit' => gists.from_redis

    if gists.list.empty?
      status 404
      return erb :invalid_gist, :locals => { :gist_id => false }
    end

    respond_to do |wants|
      wants.html { erb :list, :locals => {:gists => gists} }    # => sets content_type to text/html
      wants.json { gists.listify.to_json } # => sets content_type to application/json
      # wants.js { erb :comment }       # => views/comment.js.erb, also sets content_type to application/javascript
      wants.xml { erb :list, :locals => {:gists => gists} }    # also sets content_type to application/xml
      #
    end

  else
    redirect '/'
  end
end


get %r{(?:/)?([\w-]+)?/([\d]+)$} do
  @action = 'view'
  id = params[:captures].last
  valid = true

  @gist = Gist.new(id)

  if ! @gist.content
    @gist = false

    status 404
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


get %r{(?:/)?([\w-]+)?/([\d]+)/edit$} do
  @action = 'edit'
  id = params[:captures].last

  @gist = Gist.new(id)

  if ! @gist.content
    @gist = false

    status 404
    return erb :invalid_gist, :locals => { :gist_id => id }
  end

  @user = User.new(params[:captures].first) unless @user

  if request.url == "#{@gist.roughdraft_url}/edit" && @gist.belongs_to?(session[:github_id])
    headers 'X-Cache-Hit' => @gist.from_redis

    erb :'edit-gist'
  else
    redirect to(@gist.roughdraft_url)
  end
end


post %r{(?:/)?([\w-]+)?/([\d]+)/update$} do
  @action = 'update'
  id = params[:captures].last

  @gist = Gist.new(id)

  foo = @gist.update(params[:title], params[:contents], session)

  respond_to do |wants|
    # wants.html { erb :list, :locals => {:gists => gists} }    # => views/comment.html.haml, also sets content_type to text/html
    wants.json { foo.to_json } # => sets content_type to application/json
    # wants.js { erb :comment }       # => views/comment.js.erb, also sets content_type to application/javascript
  end
end


delete %r{(?:/)?([\w-]+)?/([\d]+)/delete$} do
  @action = 'delete'
  id = params[:captures].last

  delete = Gist.new(id).delete(session)
  GistList.new(session[:github_id]).purge


  respond_to do |wants|
    # wants.html { erb :list, :locals => {:gists => gists} }    # => views/comment.html.haml, also sets content_type to text/html
    wants.json { id } # => sets content_type to application/json
    # wants.js { erb :comment }       # => views/comment.js.erb, also sets content_type to application/javascript
  end
end


get '/new' do
  @action = 'new'

  erb :'new-gist'
end

post '/preview' do
  @action = 'preview'

  hash = Hash.new
  hash['description'] = params[:title]
  hash['files'] = Array.new

  params[:contents].each do |key, value|
    hash['files'] << Roughdraft.gist_pipeline(value["content"], params[:contents])
  end

  hash.to_json.to_s
end


post '/create' do
  params[:title]
  params[:contents]

  data = Roughdraft.github(session[:github_token]).gists.create(description: params[:title], public: true, files: params[:contents])

  respond_to do |wants|
    # wants.html { erb :list, :locals => {:gists => gists} }    # => views/comment.html.haml, also sets content_type to text/html
    wants.json { "/#{data.id.to_s}/edit".to_json } # => sets content_type to application/json
    # wants.js { erb :comment }       # => views/comment.js.erb, also sets content_type to application/javascript
  end
end


get %r{(?:/)?([\w-]+)?/([\d]+)/comments$} do
  @action = 'comments'
  id = params[:captures].last

  comments = GistComments.new(id)

  if ! comments
    status 404
    return ''
  end


  respond_to do |wants|
    # wants.html { erb :list, :locals => {:gists => gists} }    # => views/comment.html.haml, also sets content_type to text/html
    wants.json { comments.list.to_json } # => sets content_type to application/json
    # wants.js { erb :comment }       # => views/comment.js.erb, also sets content_type to application/javascript
  end
end


get '/authorize' do
  redirect to @github.authorize_url :scope => ['gist', 'user']
end


get '/authorize/return' do
  token = @github.get_token(params[:code])

  user = Roughdraft.github(token.token).users.get

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
