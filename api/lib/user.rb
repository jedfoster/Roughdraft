require 'logger'

class User < Hash
  attr_reader :user, :id

  def initialize(id, github)
    return false unless id

    @id = id
    @github = github

    @user = fetch id
  end

  def latest_gist
    GistList.new(@user[:login], @github, 1).list.first
  end

  def name
    @user[:name].to_s
  end

  def login
    @user[:login].to_s
  end

  def gravatar
    @user[:gravatar_id].to_s
  end

  def avatar
    @user[:avatar_url].to_s
  end

  def homepage
    @user[:blog].to_s
  end

  private

    def fetch(id)
      begin
        user = @github.user(id)
        ratelimit = Octokit::RateLimit.from_response @github.last_response

        log = Logger.new(STDOUT)
        log.info("API Ratelimit: #{ratelimit.remaining}/#{ratelimit.limit} (in User.fetch)")

        user.to_hash
      rescue Octokit::NotFound
        false
      end
    end
end
