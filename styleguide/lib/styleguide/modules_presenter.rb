module Styleguide
  class ModulesPresenter < Styleguide::CategoryPresenter
    def initialize(files)
      super(files, Styleguide::Modules.directory)
    end
  end
end
