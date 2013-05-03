module Styleguide
  class Module
    include Styleguide::Example

    def initialize(full_path)
      define_location(full_path, Styleguide::Modules.directory, Styleguide::Modules.sass_directory)
    end

    def partial
      File.join('modules', @full_path.dirname.basename, file_name).to_s.match(/([\w\/_-]+)/).to_s
    end

    def sass
      path =  File.join('modules', relative_to_root.dirname, friendly_name)

      files = Dir.glob(File.join(@sass_directory , relative_to_root.dirname,  friendly_name, '*.{sass,scss}').to_s)

      files.each_with_index do |file, i|
        files[i] = File.join(path, Pathname.new(file).basename('.*'))
      end
    end

    def slug
      "#{relative_to_root}.module"
    end
  end
end
