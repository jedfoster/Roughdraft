module Styleguide
  class PatternsPresenter < Styleguide::CategoryPresenter
    def initialize(files)
      super(files, Styleguide::Patterns.directory)
    end
  end
end
