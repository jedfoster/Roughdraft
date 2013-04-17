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
