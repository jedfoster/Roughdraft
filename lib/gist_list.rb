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

    @_list[:list].each do |_gist|
      gists << {
        id: _gist[:id],
        url: _gist[:url],
        description: _gist[:description] || false,
        created_at: _gist[:created_at],
        created_at_rendered: Time.parse(_gist[:created_at]).strftime("%b %-d, %Y")
      }
    end

    hash = {
      list: gists,
      page_count: @list[:page_count],
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


  private

    def fetch
      begin
        gists = Array.new

        github_response = @github.gists(@user_id)
        ratelimit = Octokit::RateLimit.from_response @github.last_response

        log = Logger.new(STDOUT)
        log.info("API Ratelimit: #{ratelimit.remaining}/#{ratelimit.limit} (in GistList.fetch)")

        github_response.each do |_gist|
          _gist.files.each do |key, file|
            if Gist.is_allowed file.language.to_s, file.filename.to_s
              _gist.description = Roughdraft.safe_html(_gist.description)
              _gist.url = Roughdraft.url(@user_id, _gist.id, Roughdraft.slugify_description(_gist.description))
              gists << _gist.to_hash
              break
            end
          end
        end

        hash = {
          list: gists,
          page_count: @github.last_response.rels[:last].href.match(/page=(\d+)$/)[1],
          links: {
            next: @github.last_response.rels[:next] ? @github.last_response.rels[:next].href.scan(/&page=(\d)/).first.first : nil,
            prev: @github.last_response.rels[:prev] ? @github.last_response.rels[:prev].href.scan(/&page=(\d)/).first.first : nil,
          }
        }

        hash

      rescue Octokit::NotFound
        false
      end
    end
end
