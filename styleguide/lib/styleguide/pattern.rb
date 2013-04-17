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

