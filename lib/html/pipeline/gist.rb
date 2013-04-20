module HTML
  class Pipeline
    class GistFilter < Filter
      def call
        doc.search("gist").each do |gist|
          file = GistFile.new(gist.text.to_s, context[:gist])

          pipe = HTML::Pipeline.new [
            HTML::Pipeline::MarkdownFilter
          ], @context

          sub_gist = pipe.call("```#{file.language}\n#{file.content}\n```")[:output].to_s

          if gist.parent.node_name == 'p'
            gist.parent.replace sub_gist
          else
            gist.replace sub_gist
          end
        end
        doc
      end

      private

      class GistFile
        def initialize(filename, gist)
          @file = gist["files"][filename]
        end

        def language
          @file["language"].to_s.downcase
        end

        def content
          @file["content"].to_s
        end
      end
    end
  end
end