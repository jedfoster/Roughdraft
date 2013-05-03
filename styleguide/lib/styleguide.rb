module Styleguide
  def self.view_path
    File.join(Sinatra::Application.root, '..', 'views')
  end

  def self.sass_path
    File.join(Sinatra::Application.root, '..', 'sass')
  end
  
  
  
  
  module Example
    def display_name
      friendly_name.humanize
    end

    def friendly_name
      file_name.to_s.match(/([[:alnum:]-]+)/)[0].to_s
    end

    def partial
      return "path: #{@full_path.relative_path_from(Pathname.new(views_folder))}"
      
      path = @full_path.relative_path_from(Pathname.new(views_folder))
      File.join(path.dirname, file_name).to_s.match(/([\w\/_-]+)/).to_s
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
      File.join(Sinatra::Application.root, 'views')
    end
  end
  
  
  
  
  
  
  
  
  
  
  

  class Presenter
    def initialize(type)
      puts Styleguide::view_path
    end
  end
  
  class Modules
  end
  
  class Patterns
  end

end