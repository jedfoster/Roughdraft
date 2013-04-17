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
