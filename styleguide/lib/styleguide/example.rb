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
