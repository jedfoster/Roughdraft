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


set :partial_template_engine, :erb

# enable :sessions

configure :production do
  helpers do
    def github(auth_token = '')
      github = Github.new do |config|
        config.client_id = ENV['GITHUB_ID']
        config.client_secret = ENV['GITHUB_SECRET']
        config.oauth_token = auth_token
      end
    end

    use Rack::Session::Cookie, #:key => 'sassmeister.com',
                               #:domain => 'sassmeister.com',
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

    use Rack::Session::Cookie, :key => 'sassmeister.dev',
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

  if( ! files["#{files.keys.grep(/.+\.(scss|sass)/)[0]}"])
    syntax = plugin = ''
    sass = "// Sorry, I couldn't find any valid Sass in that Gist."

  else
    sass = files["#{files.keys.grep(/.+\.(scss|sass)/)[0]}"].content

    if files["#{files.keys.grep(/.+\.(scss|sass)/)[0]}"].filename.end_with?("scss")
      syntax = 'scss'
    else
      syntax = 'sass'
    end

    comments = sass.scan(/^\/\/.+/).each {|x| x.sub!(/\/\/\s*/, '').sub!(/\s{1,}v[\d\.]+.*$/, '')}
    comments.delete_if { |x| ! @plugins.key?(x)}
    plugin = comments[0]

    sass.gsub!(/^\s*(@import.*)\s*/, "\n// #{'\1'}\n\n")
  end

  erb :index
end
