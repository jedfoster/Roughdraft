module Styleguide
  module Patterns

    @@pattern_directory = File.join(Sinatra::Application.root, '..', 'views', 'ui_patterns')
    @@pattern_sass_directory = File.join(Sinatra::Application.root, '..', 'sass', 'ui_patterns')

    def self.directory
      Pathname.new(@@pattern_directory)
    end

    def self.sass_directory
      Pathname.new(@@pattern_sass_directory)
    end
  end
end
