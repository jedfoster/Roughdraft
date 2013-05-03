module Styleguide
  class Pattern
    include Styleguide::Example

    def initialize(full_path)
      define_location(full_path, Styleguide::Patterns.directory, Styleguide::Patterns.sass_directory)
    end
    
    def partial
      File.join('ui_patterns', @full_path.dirname.basename, file_name).to_s.match(/([\w\/_-]+)/).to_s
    end
    
    def sass
      path =  File.join('ui_patterns', relative_to_root.dirname, friendly_name)

      files = Dir.glob(File.join(@sass_directory , relative_to_root.dirname,  friendly_name, '*.{sass,scss}').to_s)

      files.each_with_index do |file, i|
        files[i] = File.join(path, Pathname.new(file).basename('.*'))
      end
    end

    def slug
      "#{relative_to_root}.pattern"
    end
  end
end

