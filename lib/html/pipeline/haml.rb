module HTML
  class Pipeline
    class HamlFilter < TextFilter

      def initialize(text, context = nil, result = nil)
        super text, context, result
      end

      def call
        begin
          html = Haml::Engine.new(@text, {:suppress_eval => true}).render

          html.rstrip!
          html
        rescue Haml::Error => e
          @text = "```haml\n#{@text}\n```"

          pipe = HTML::Pipeline.new [
            HTML::Pipeline::MarkdownFilter,
            HTML::Pipeline::SanitizationFilter
          ], context

          "<p class='error'><strong>Haml Error</strong><br/>
            Roughdraft does not support some Haml features, such as Ruby evaluation and filters. Below is the unrendered Haml.
            </p>
          #{pipe.call(@text)[:output].to_xhtml}"

        rescue Haml::SyntaxError => e
          "Haml syntax error: #{e}"
        end
      end
    end
  end
end