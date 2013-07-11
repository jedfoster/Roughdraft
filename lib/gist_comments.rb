class GistComments
  include Enumerable

  attr_reader :from_redis, :page

  def each
    @list.each { |i| yield i }
  end

  def initialize(gist_id, page = 1)
    @gist_id = gist_id
    @from_redis = 'True'
    @page = page
    @list = REDIS.get("gist-comments: #{gist_id}, pg: #{page}")

    if ! @list
      @from_redis = 'False'

      @list = fetch
    else
      @list = JSON.parse(@list)
    end
  end

  def list
    @list["list"]
  end

  def links
    @list["links"]
  end

  private

    def fetch
      begin
        comments = Array.new

        github_response =Github::Gists.new(id: @gist_id, client_id: Roughdraft.gh_config['client_id'], client_secret: Roughdraft.gh_config['client_secret']).comments.all(@gist_id)

        github_response.each do |comment|
          comment.body_rendered = pipeline(comment.body).gsub(/<pre (.+?)>\s+<code>/, '<pre \1><code>').gsub(/<\/code>\s+<\/pre>/, '</code></pre>')
          comment.created_at_formatted = Time.parse(comment.created_at).strftime("%b %-d, %Y")
          comment.user.delete_if { |key| key.to_s.match /^(.*url|id|type)$/ }
          comments << comment.to_hash
        end

        hash = {
          "list" => comments,
          "page_count" => github_response.count_pages,
          "links" => {
            "next" => github_response.links.next ? github_response.links.next.scan(/&page=(\d)/).first.first : nil,
            "prev" => github_response.links.prev ? github_response.links.prev.scan(/&page=(\d)/).first.first : nil,
          }
        }

        REDIS.setex("gist-comments: #{@gist_id}, pg: #{@page}", 60, hash.to_json)
        hash

      rescue Github::Error::NotFound
        false
      end
    end
    
    def pipeline(html)
      context = {
        :gfm => true,
        :asset_root => "http://#{APP_DOMAIN}/images",
        # :base_url   => "#{APP_DOMAIN}"
      }

      pipe = HTML::Pipeline.new [
        HTML::Pipeline::MarkdownFilter,
        HTML::Pipeline::SanitizationFilter,
        HTML::Pipeline::ImageMaxWidthFilter,
        HTML::Pipeline::EmojiFilter
      ], context

      pipe.call(html)[:output].to_xhtml # return XHTML to be compatible with RSS
    end
      
      

end
