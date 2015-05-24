require 'logger'

class GistList
  include Enumerable

  attr_reader :page

  def each
    @_list.each { |i| yield i }
  end

  def initialize(user_id, github, page = 1)
    @user_id = user_id
    @page = page
    @github = github

    @_list = fetch
  end

  def listify
    gists = Array.new

    @_list[:list].each do |gist|
      gists << {
        id: gist[:id],
        url: gist[:url],
        description: gist[:description] || false,
        created_at: gist[:created_at],
        created_at_rendered: gist[:created_at].strftime("%b %-d, %Y")
      }
    end

    hash = {
      list: gists,
      page_count: @_list[:page_count],
      links: {
        next: links[:next],
        prev: links[:prev],
      }
    }

    hash
  end

  def list
    @_list[:list]
  end

  def links
    @_list[:links]
  end

  def belong_to? user
    # require 'pry-remote'; binding.remote_pry
    @github.user_authenticated? && user == @user_id
  end


  private

    def fetch
      begin
        gists = Array.new

        github_response = @github.gists(@user_id, per_page: 50, page: @page)
        ratelimit = Octokit::RateLimit.from_response @github.last_response

        log = Logger.new(STDOUT)
        log.info("API Ratelimit: #{ratelimit.remaining}/#{ratelimit.limit} (in GistList.fetch)")

        github_response.each do |gist|
          gist.files.each do |key, file|
            if Gist.is_allowed file.language.to_s, file.filename.to_s
              gist.description = Roughdraft.safe_html(gist.description)
              gist.url = Roughdraft.url(@user_id, gist.id, Roughdraft.slugify_description(gist.description))
              gists << gist.to_hash
              break
            end
          end
        end

        last_page = @github.last_response.rels[:last]
        next_page = @github.last_response.rels[:next]
        prev_page = @github.last_response.rels[:prev]

        hash = {
          list: gists,
          page_count: last_page.nil? ? 0 : last_page.href.match(/\Wpage=(\d+)/)[1],
          links: {
            next: next_page.nil? ? nil : next_page.href.match(/\Wpage=(\d+)/)[1],
            prev: prev_page.nil? ? nil : prev_page.href.match(/\Wpage=(\d+)/)[1],
          }
        }

        hash

      rescue Octokit::NotFound
        false
      end
    end
end
