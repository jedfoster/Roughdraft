require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/partial'
require 'sinatra/respond_to'
require 'chairman'
require 'json'
require 'github_api'
require 'rack/request'
require 'yaml'
require 'html/pipeline'
require 'RedCloth'
require 'haml'
require 'redis'

require './lib/rack/request.rb'
require './lib/gist.rb'
require './lib/user.rb'
require './lib/gist_list.rb'
require './lib/gist_comments.rb'
require './lib/html/pipeline/haml.rb'
require './lib/html/pipeline/gist.rb'
require './lib/roughdraft.rb'


class RoughdraftApp < Sinatra::Base
  register Sinatra::RespondTo
  register Sinatra::Partial

  HTML::Pipeline::SanitizationFilter::WHITELIST[:attributes][:all].push 'class'

  set :partial_template_engine, :erb

  set(:subdomain) { |num_subdomains| condition { request.subdomains.count == num_subdomains } }


  configure do
    require 'redis'
    redisUri = ENV["REDISTOGO_URL"] || 'redis://localhost:6379'
    uri = URI.parse(redisUri)
    REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  end

  configure :production do
    require 'newrelic_rpm'

    APP_DOMAIN = 'roughdraft.io'

    helpers do
      use Rack::Session::Cookie, :key => 'roughdraft.io',
                                 :domain => '.roughdraft.io',
                                 :path => '/',
                                 :expire_after => 7776000, # 90 days, in seconds
                                 :secret => ENV['COOKIE_SECRET']
    end

    Chairman.config(ENV['GITHUB_ID'], ENV['GITHUB_SECRET'], ['gist', 'user'])
  end

  configure :development do
    APP_DOMAIN = 'roughdraft.dev'

    helpers do
      use Rack::Session::Cookie, :key => 'roughdraft.dev',
                                 # :domain => :all,
                                 :domain => '.roughdraft.dev',
                                 :path => '/',
                                 :expire_after => 7776000, # 90 days, in seconds
                                 :secret => 'local'
    end

    yml = YAML.load_file("config/github.yml")
    Chairman.config(yml["client_id"], yml["client_secret"], ['gist', 'user'])
  end


  helpers do
    include ERB::Util
    alias_method :code, :html_escape

    include Roughdraft
  end


  before do
    @user = @gist = @action = false
    @github = Chairman.session(session[:github_token])
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
        wants.html { erb :list, :locals => {:gists => gists} }
        wants.json { gists.listify.to_json }
        wants.xml { erb :list, :locals => {:gists => gists} }
      end

    else
      redirect '/'
    end
  end


  get %r{(?:/)?([\w-]+)?/([\w]+)$} do
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


  get %r{(?:/)?([\w-]+)?/([\w]+)/edit$} do
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


  post %r{(?:/)?([\w-]+)?/([\w]+)/update$} do
    @action = 'update'
    id = params[:captures].last

    @gist = Gist.new(id)

    foo = @gist.update(params[:title], params[:contents], session)

    respond_to do |wants|
      wants.json { foo.to_json }
    end
  end


  delete %r{(?:/)?([\w-]+)?/([\w]+)/delete$} do
    @action = 'delete'
    id = params[:captures].last

    delete = Gist.new(id).delete(session)
    GistList.new(session[:github_id]).purge

    respond_to do |wants|
      wants.json { id }
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
      html = Hashie::Mash.new

      ext = File.extname(key)

      if ext.match(/\.(textile)/)
        html.language = 'Textile'
      elsif ext.match(/\.(haml)/)
        html.language = 'Haml'
      else
        html.language = 'Markdown'
      end

      html.content = value["content"]

      hash['files'] << Roughdraft.gist_pipeline(html, params[:contents])
    end

    hash.to_json.to_s
  end


  post '/create' do
    params[:title]
    params[:contents]

    data = Chairman.session(session[:github_token]).gists.create(description: params[:title], public: true, files: params[:contents])

    respond_to do |wants|
      wants.json { "/#{data.id.to_s}/edit".to_json }
    end
  end


  get %r{(?:/)?([\w-]+)?/([\w]+)/comments$} do
    @action = 'comments'
    id = params[:captures].last

    comments = GistComments.new(id)

    if ! comments
      status 404
      return ''
    end

    respond_to do |wants|
      wants.json { comments.list.to_json }
    end
  end


  use Chairman::Routes
  
  # implement redirects
  class Chairman::Routes 
    configure :production do
      helpers do
        use Rack::Session::Cookie, :key => 'roughdraft.io',
                                   :domain => '.roughdraft.io',
                                   :path => '/',
                                   :expire_after => 7776000, # 90 days, in seconds
                                   :secret => ENV['COOKIE_SECRET']
       end
    end

    configure :development do
      helpers do
        use Rack::Session::Cookie, :key => 'roughdraft.dev',
                                   :domain => '.roughdraft.dev',
                                   :path => '/',
                                   :expire_after => 7776000, # 90 days, in seconds
                                   :secret => 'local'
      end
    end    
    
    after '/authorize/return' do
      redirect to("http://#{@user.login}.#{RoughdraftApp::APP_DOMAIN}/")
    end

    after '/logout' do
      redirect to('/')
    end
  end

  run! if app_file == $0
end
