module Styleguide
  class Fixtures
    @@fixtures = {
    }

    def self.get(module_path)
      @@fixtures[module_path]
    end
  end
end

