require 'logger'

class GistComments
  include Enumerable

  attr_reader :page

  def each
    @list.each { |i| yield i }
  end

  def initialize(gist_id, github, page = 1)
    @gist_id = gist_id
    @github = github
    @page = page

    @list = fetch
  end

  def list
    if @list
      @list[:list]
    else
      false
    end
  end

  def links
    @list[:links]
  end

  private

    def fetch
      begin
        comments = Array.new

        github_response = @github.gist_comments(@gist_id)
        ratelimit = Octokit::RateLimit.from_response @github.last_response
          
        log = Logger.new(STDOUT)
        log.info("API Ratelimit: #{ratelimit.remaining}/#{ratelimit.limit} (in GistComments.fetch)")

        return false if github_response.count < 1

        github_response.each do |comment|
          comment.body_rendered = pipeline(comment.body).gsub(/<pre (.+?)>\s+<code>/, '<pre \1><code>').gsub(/<\/code>\s+<\/pre>/, '</code></pre>')
          comment.created_at_formatted = comment.created_at.strftime("%b %-d, %Y")
          comment.user.delete_if { |key| key.to_s.match /^(.*url|id|type)$/ }
          comments << comment.to_hash
        end

        last_page = @github.last_response.rels[:last]
        next_page = @github.last_response.rels[:next]
        prev_page = @github.last_response.rels[:prev]

        hash = {
          list: comments,
          page_count: last_page.nil? ? 0 : last_page.href.match(/\Wpage=(\d+)$/)[1],
          links: {
            next: next_page.nil? ? nil : next_page.href.scan(/\Wpage=(\d)/).first.first,
            prev: prev_page.nil? ? nil : prev_page.href.scan(/\Wpage=(\d)/).first.first,
          }
        }

        hash

      rescue Octokit::NotFound
        false
      end
    end

    def pipeline(html)
      context = {
        :gfm => true,
        :asset_root => "http://#{RoughdraftApp::APP_DOMAIN}/images",
        :base_url   => "https://github.com"
      }

      pipe = HTML::Pipeline.new [
        HTML::Pipeline::MarkdownFilter,
        HTML::Pipeline::SanitizationFilter,
        HTML::Pipeline::ImageMaxWidthFilter,
        HTML::Pipeline::MentionFilter,
        HTML::Pipeline::EmojiFilter
      ], context

      pipe.call(html)[:output].to_xhtml # return XHTML to be compatible with RSS
    end
end
