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
    gsub(/_id$/, "").gsub(/_/, " ").capitalize
  end
end

module Styleguide
  class Category
    attr_reader :files
    def initialize(dir, root, files)
      @files = files
      @dir = dir
      @root = root
    end

    def display_name
      return 'Misc' if root?
      join_category_names
    end

    private

    def root?
      @dir == @root
    end

    def relative_to_root
      @dir.relative_path_from(@root)
    end

    def join_category_names
      relative_to_root.each_filename.map { |name| name.to_s.humanize }.join(' - ')
    end
  end
end


module Styleguide
  class CategoryPresenter
    def initialize(files, root)
      @files = files
      @root = root
    end

    def categories
      directories_sorted_alphabetically.map { |dir| Styleguide::Category.new(dir, @root, files_sorted_alphabetically(dir)) }
    end

    private

    def directories_sorted_alphabetically
      @files.map { |file| file.directory }.uniq.sort
    end

    def files_sorted_alphabetically(dir)
      @files.select { |file| file.directory == dir }.sort { |a,b| a.file_name <=> b.file_name }
    end
  end
end

module Styleguide
  class FileLocator
    def self.patterns
      templates_in_directory(Styleguide::Patterns.directory).map { |file| Styleguide::Pattern.new(file) }
    end

    def self.modules
      templates_in_directory(Styleguide::Modules.directory).map { |file| Styleguide::Module.new(file) }
    end

    def self.get(path, type)
      if type == 'pattern'
        Styleguide::Pattern.new(File.join(Styleguide::Patterns.directory, path))
      else
        Styleguide::Module.new(File.join(Styleguide::Modules.directory, path))
      end
    end

    private

    def self.templates_in_directory(directory)
      Dir.glob(File.join(directory, '**', '*.{haml,erb}'))
    end
  end
end

module Styleguide
  module Modules
    @@module_directory = File.join(Sinatra::Application.root, 'views', 'modules')
    @@module_sass_directory = File.join(Sinatra::Application.root, 'assets', 'stylesheets', 'modules')

    def self.directory
      Pathname.new(@@module_directory)
    end

    def self.sass_directory
      Pathname.new(@@module_sass_directory)
    end
  end
end




module Styleguide
  module Example

    attr_reader :full_path

    def define_location(full_path, root_directory, sass_directory)
      @full_path = Pathname.new(full_path)
      @root_directory = root_directory
      @sass_directory = sass_directory
    end

    def display_name
      friendly_name.humanize
    end

    def friendly_name
      file_name.to_s.match(/_([a-zA-Z0-9_-]*)\..*/)[1]
    end

    def partial
      path = @full_path.relative_path_from(Pathname.new(views_folder))
      File.join(path.dirname, friendly_name)
    end

    def sass_path
      Dir.glob(File.join(@sass_directory , relative_to_root.dirname,  friendly_name, '*.{sass,scss}'))
    end

    def directory
      @full_path.dirname
    end

    def file_name
      @full_path.basename
    end

    def relative_to_root
      @full_path.relative_path_from(@root_directory)
    end

    def markdown
      instructions = Dir.glob(File.join(@full_path.dirname, '*.{md,markdown}'))
      return if instructions.empty?
      IO.read(instructions[0]) if File.exists?(instructions[0])
    end

    private

    def views_folder
      File.join(Rails.root, 'app', 'views')
    end
  end
end



module Styleguide
  module Patterns

    @@pattern_directory = File.join(Sinatra::Application.root, 'views', 'ui_patterns')
    @@pattern_sass_directory = File.join(Sinatra::Application.root, 'assets', 'stylesheets', 'ui_patterns')

    def self.directory
      Pathname.new(@@pattern_directory)
    end

    def self.sass_directory
      Pathname.new(@@pattern_sass_directory)
    end
  end
end

module Styleguide
  class Module
    include Styleguide::Example

    def initialize(full_path)
      define_location(full_path, Styleguide::Modules.directory, Styleguide::Modules.sass_directory)
    end

    def slug
      "#{relative_to_root}.module"
    end
  end
end

module Styleguide
  class Pattern
    include Styleguide::Example

    def initialize(full_path)
      define_location(full_path, Styleguide::Patterns.directory, Styleguide::Patterns.sass_directory)
    end

    def slug
      "#{relative_to_root}.pattern"
    end
  end
end




module Styleguide
  class ModulesPresenter < Styleguide::CategoryPresenter
    def initialize(files)
      super(files, Styleguide::Modules.directory)
    end
  end
end

module Styleguide
  class PatternsPresenter < Styleguide::CategoryPresenter
    def initialize(files)
      super(files, Styleguide::Patterns.directory)
    end
  end
end






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
    file = File.new(File.join('../sass', file + '.scss'))

    code_toggle file.read(), file.path, file.mtime
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
  

get %r{([\w\./_-]+)} do
  if File.exists?('views' + params[:captures].first.gsub(/.(\/)$/, '') + '/index.erb')
    erb :"#{params[:captures].first.gsub(/.(\/)$/, '')}/index"
  else
    erb :"#{params[:captures].first}"
  end
end