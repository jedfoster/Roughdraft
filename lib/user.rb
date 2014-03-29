require 'logger'

class User < Hash
  attr_reader :user, :id

  def initialize(id)
    return false unless id

    @user = RoughdraftApp::REDIS.get(id)
    @id = id

    if ! @user
      @user = fetch id
    else
      @user = JSON.parse(@user)
    end
  end

  def latest_gist
    GistList.new(@user['login'], 1).list.first
  end

  def name
    @user['name'].to_s
  end

  def login
    @user['login'].to_s
  end

  def gravatar
    @user['gravatar_id'].to_s
  end

  def homepage
    @user['blog'].to_s
  end

private
  def fetch(id)
    begin
      user = Github::Users.new.get(user: id, client_id: Chairman.client_id, client_secret: Chairman.client_secret)

      log = Logger.new(STDOUT)
      log.info("API Ratelimit: #{user.headers.ratelimit_remaining}/#{user.headers.ratelimit_limit} (in User.fetch)")

      RoughdraftApp::REDIS.setex(user['login'], 60, user.to_hash.to_json)
      user.to_hash
    rescue Github::Error::NotFound
      false
    end
  end
end
