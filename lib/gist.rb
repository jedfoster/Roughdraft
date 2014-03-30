require 'logger'

class Gist
  attr_reader :from_redis, :content

  def initialize(gist_id)
    @from_redis = 'True'
    @content = RoughdraftApp::REDIS.get(gist_id)
    @gist_id = gist_id

    if ! @content
      @from_redis = 'False'
      @content = fetch
    else
      @content = JSON.parse(@content)
    end
  end

  def self.is_allowed(language, filename)
    return false if language.nil? || filename.match('SassMeister-input')

    return (language.match(/(Markdown|Literate CoffeeScript|Textile|Haml)/) || File.extname(filename) == '.txt')
  end

  def owner
    @content["owner"]["login"].to_s
  end

  def belongs_to?(user_login)
    return false unless user_login

    owner.downcase == user_login.downcase
  end

  def roughdraft_url
    "http://#{owner.downcase}.#{RoughdraftApp::APP_DOMAIN}/#{@gist_id}"
  end

  def id
    @gist_id
  end

  def description
    @content["description"].to_s
  end

  def description_safe
    @safe_description ||= Roughdraft.safe_html(description)
  end

  def files
    @content["files"]
  end

  def file_content(file, content)
    @content["files"][file]["content"] = content
    @content["files"][file]["rendered"] = Roughdraft.gist_pipeline(content.to_s, @content)
  end

  def html_url
    @content["html_url"].to_s
  end

  def update(description, files, session)
    Chairman.session(session[:github_token]).gists.edit(id, description: description, files: files)
    @content = fetch
  end

  def delete(session)
    return Chairman.session(session[:github_token]).gists.delete(id)
  end

  private

    def fetch
      begin
        gist = Github::Gists.new.get(@gist_id, client_id: Chairman.client_id, client_secret: Chairman.client_secret)

        log = Logger.new(STDOUT)
        log.info("API Ratelimit: #{gist.headers.ratelimit_remaining}/#{gist.headers.ratelimit_limit} (in Gist.fetch)")

        gist.files.each do |file, value|
          if Gist.is_allowed value.language.to_s, value.filename.to_s
            value[:rendered] = Roughdraft.gist_pipeline(value, gist).gsub(/<pre(.*?)>\s+<code>/, '<pre\1><code>').gsub(/<\/code>\s+<\/pre>/, '</code></pre>')
              .gsub(/<sassmeister>([\d]+)\s*<\/sassmeister>/, '<p class="sassmeister" data-gist-id="\1" data-height="480"><a href="http://sassmeister.com/gist/\1">Play with this gist on SassMeister.</a></p><script src="http://static.sassmeister.com/js/embed.js" async></script>')

          end
        end

        RoughdraftApp::REDIS.setex(@gist_id, 60, gist.to_hash.to_json.to_s)
        gist.to_hash

      rescue Github::Error::NotFound
        false
      end
    end
end
