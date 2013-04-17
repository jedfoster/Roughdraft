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
      relative_to_root.each_filename.map { |name| name.humanize }.join(' - ')
    end
  end
end
