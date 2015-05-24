require 'logger'

class Gist
  attr_reader :content

  def initialize(gist_id, github)
    @gist_id = gist_id
    @github = github

    @content = fetch
  end

  def self.is_allowed(language, filename)
    return false if language.nil? || filename.match('SassMeister-input')

    return (language.match(/(Markdown|Literate CoffeeScript|Textile|Haml)/) || File.extname(filename) == '.txt')
  end

  def owner
    @content[:owner].to_s
  end

  def belongs_to?(user_login)
    return false unless user_login

    owner.downcase == user_login.downcase
  end

  def roughdraft_url
    Roughdraft.url(owner.downcase, @gist_id, slug)
  end

  def roughdraft_edit_url
    Roughdraft.url(owner.downcase, @gist_id, '/edit')
  end

  def id
    @gist_id
  end

  def description
    @content[:description].to_s
  end

  def description_safe
    @safe_description ||= Roughdraft.safe_html(description)
  end

  def slug
    @slug ||= Roughdraft.slugify_description(description_safe)
  end

  def files
    @content[:files].to_hash
  end

  def html_url
    @content[:html_url].to_s
  end

  def update(description, files, session)
    @github.edit_gist(id, description: description, files: files)
    @content = fetch
  end

  def delete
    @github.delete_gist @gist_id
  end

  private

    def fetch
      begin
        @gist = @github.gist(@gist_id)
        ratelimit = Octokit::RateLimit.from_response @github.last_response

        @gist[:owner] = @gist.owner.login
        @gist[:updated_at] = @gist.updated_at

        log = Logger.new(STDOUT)
        log.info("API Ratelimit: #{ratelimit.remaining}/#{ratelimit.limit} (in Gist.fetch)")

        @gist.files.each do |file, value|
          if Gist.is_allowed value.language.to_s, value.filename.to_s
            value[:rendered] = Roughdraft.gist_pipeline(value, @gist).gsub(/<pre(.*?)>\s+<code>/, '<pre\1><code>').gsub(/<\/code>\s+<\/pre>/, '</code></pre>')
              .gsub(/<sassmeister>([\d]+)\s*<\/sassmeister>/, '<p class="sassmeister" data-gist-id="\1" data-height="480"><a href="http://sassmeister.com/gist/\1">Play with this gist on SassMeister.</a></p><script src="http://static.sassmeister.com/js/embed.js" async></script>')

          end
        end

        @gist.to_hash

      rescue Octokit::NotFound
        false
      end
    end
end
