module Styleguide
  module Modules
    @@module_directory = File.join(Sinatra::Application.root, '..', 'views', 'modules')
    @@module_sass_directory = File.join(Sinatra::Application.root, '..', 'sass', 'modules')

    def self.directory
      Pathname.new(@@module_directory)
    end

    def self.sass_directory
      Pathname.new(@@module_sass_directory)
    end
  end
end
