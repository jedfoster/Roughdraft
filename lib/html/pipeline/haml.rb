module HTML
  class Pipeline
    class HamlFilter < TextFilter
      
      def initialize(text, context = nil, result = nil)
        super text, context, result
      end
      
      def call
        html = Haml::Engine.new(@text, {:suppress_eval => true}).render

        html.rstrip!
        html
      end      
    end
  end
end


