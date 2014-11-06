require 'logger'

class GistList
  include Enumerable

  attr_reader :from_redis, :page

  def each
    @list.each { |i| yield i }
  end

  def initialize(user_id, github, page = 1)
    @user_id = user_id
    @from_redis = 'True'
    @page = page
    @list = RoughdraftApp::REDIS.get("gist-list: #{user_id}, pg: #{page}")
    @github = github


    if ! @list
      @from_redis = 'False'

      @list = fetch
    else
      @list = JSON.parse(@list)
    end

    @list.symbolize_keys!
  end

  def listify
    gists = Array.new

    @list[:list].each do |gist|
      gists << {
        :id => gist["id"],
        :url => gist['url'],
        :description => gist["description"] || false,
        :created_at => gist["created_at"],
        :created_at_rendered => Time.parse(gist['created_at']).strftime("%b %-d, %Y")
      }
    end

    hash = {
      "list" => gists,
      "page_count" => @list[:page_count],
      "links" => {
        "next" => links["next"],
        "prev" => links["prev"],
      }
    }

    hash
  end

  def list
    @list[:list]
  end

  def links
    @list[:links]
  end

  def purge
    RoughdraftApp::REDIS.keys("gist-list: #{@user_id}, pg: *").each do |key|
      RoughdraftApp::REDIS.del(key)
    end
  end


  private

    def fetch
      begin
        gists = Array.new

        github_response = @github.gists()
        ratelimit = Octokit::RateLimit.from_response @github.last_response

        log = Logger.new(STDOUT)
        log.info("API Ratelimit: #{ratelimit.remaining}/#{ratelimit.limit} (in GistList.fetch)")

        github_response.each do |gist|
          gist.files.each do |key, file|
            if Gist.is_allowed file.language.to_s, file.filename.to_s
              gist.description = Roughdraft.safe_html(gist["description"])
              gist[:url] = Roughdraft.url(@user_id, gist.id, Roughdraft.slugify_description(gist.description))
              gists << gist.to_hash
              break
            end
          end
        end

        require 'pry-remote'
        binding.remote_pry

        hash = {
          "list" => gists,
          "page_count" => @github.last_response.rels[:last].href.match(/page=(\d+)$/)[1],
          "links" => {
            "next" => github_response.links.next ? github_response.links.next.scan(/&page=(\d)/).first.first : nil,
            "prev" => github_response.links.prev ? github_response.links.prev.scan(/&page=(\d)/).first.first : nil,
          }
        }

        RoughdraftApp::REDIS.setex("gist-list: #{@user_id}, pg: #{@page}", 60, hash.to_json)
        hash

      rescue Octokit::NotFound
        false
      end
    end
end
