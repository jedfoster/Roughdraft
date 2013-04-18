# Those little ditties that Sinatra needs to make the magic happen
# -----------------------------------------------------------------------
require 'rubygems'
require 'net/http'

# If you're using bundler, you will need to add this
require 'bundler/setup'

require 'sinatra'
require 'sinatra/partial'

require 'rdiscount'

set :partial_template_engine, :erb
set :public_folder, '../public'



class String
  def humanize
    gsub(/\//, "").gsub(/_/, " ").capitalize
  end
end

require './lib/styleguide/category.rb'
require './lib/styleguide/category_presenter.rb'
require './lib/styleguide/file_locator.rb'
require './lib/styleguide/modules.rb'
require './lib/styleguide/example.rb'
require './lib/styleguide/patterns.rb'
require './lib/styleguide/module.rb'
require './lib/styleguide/pattern.rb'
require './lib/styleguide/modules_presenter.rb'
require './lib/styleguide/patterns_presenter.rb'






# Helpers to add a new horn section to the band
# -----------------------------------------------------------------------
helpers do
  include ERB::Util
  alias_method :code, :html_escape
  alias_method :md, :markdown

  # write better links
  def link_to_unless_current(location, text )
    if request.path_info == location
      text
    else
      link_to location, text
    end
  end

  def link_to(url,text=url,opts={})
    attributes = ""
    opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\" "}
    "<a href=\"#{url}\" #{attributes}>#{text}</a>"
  end
  
  def example_file(file_name)
    file = File.new(file_name)
    render :partial => 'admin/styleguide/module_example', :locals => file_hash(file)
  end


  # html_example is a convenienence method that wraps ERB partial @file in our standard example markup
  # with the rendered HTML in an <article> and the code in a collapsible div below.
  #
  # Use in a view as
  #   <%= html_example 'ui_patterns/typography/_body_copy' %>
  #
  # @param file path to an ERB partial, relative to /views and omitting the extension,
  #             e.g.: 'ui_patterns/typography/_body_copy'

  def html_example(file)
    file = File.new(File.join('views', file + '.erb'))

    partial :'shared/_html_example', :locals => { :content => file.read(), :mtime => file.mtime, :path => file.path }
  end


  # sass_example is the same as html_example, but for Sass partials.
  #
  # Use in a view as
  #   <%= sass_example 'forms/_extends' %>
  #
  # @param file path to an SCSS partial, relative to /sass and omitting the extension,
  #             e.g.: 'forms/_extends'

  def sass_example(file)
    file = File.new(file)

    code_toggle file.read(), Pathname.new(file.path).relative_path_from(Pathname.new(Sinatra::Application.root)), file.mtime
  end


  # code_toggle is a internal convenience method that wraps our collapsible example code div.
  # You shouldn't need to use it directly.
  #
  # @param content  string of HTML or SCSS content
  # @param path     path to the file being displayed
  # @param mtime    mtime of the file being displayed

  def code_toggle(content, path, mtime)
    partial :'shared/_code_toggle', :locals => { :content => content, :mtime => mtime, :path => path }
  end

end


# Without this, there is no app. No really, there is nothing.
# -----------------------------------------------------------------------
get '/' do
  erb :typography
end

get %r{(modules|patterns)([\w\./_-]*)}i do
  if ! params[:captures].last.to_s.empty?
    return params[:captures].last.to_s
  else
    if params[:captures].first.to_s == 'modules'
      @presenter = Styleguide::ModulesPresenter.new(Styleguide::FileLocator.modules)
    else
      @presenter = Styleguide::ModulesPresenter.new(Styleguide::FileLocator.modules)
    end

    
    erb :"#{params[:captures].first.to_s}"
  end
end

get %r{/examples/([\w\./_-]+?)\.(module|pattern)} do
  @example = Styleguide::FileLocator.get(params[:captures].first.to_s, params[:captures].last.to_s)
  @data = ''
  erb :show
end
  

get %r{([\w\./_-]+)} do
  if File.exists?('views' + params[:captures].first.gsub(/.(\/)$/, '') + '/index.erb')
    erb :"#{params[:captures].first.gsub(/.(\/)$/, '')}/index"
  else
    erb :"#{params[:captures].first}"
  end
end