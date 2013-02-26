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
  
  
  class Gist
    attr_accessor :content, :created_at, :updated_at, :language
  end
end                         

before do
  @github = github(session[:github_token])
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


get %r{/gist(?:/[\w]*)*/([\d]+)} do
  files = @github.gists.get(params[:captures].first).files
  
  @gists = Array.new
  
  files.each do |file|
    puts file.first.to_s
    gist = Gist.new
    
    if is_allowed file.last.language
      # @gist.content = file.last.content
      # @gist.content = file.first
      gist.content = GitHub::Markup.render(file.first.to_s, file.last.content.to_s)
      
      @gists << gist
    else
      gist.content = "Hello world #{file.last.language}"
      @gists << gist
    end
  end

  erb :index
end
