class Gist
  attr_reader :from_redis, :content

  def initialize(gist_id)
    @from_redis = 'True'
    @content = REDIS.get(gist_id)
    @gist_id = gist_id

    if ! @content
      @from_redis = 'False'
      @content = fetch
    else
      @content = JSON.parse(@content)
    end
  end

  def self.is_allowed(language)
    return false if language.nil?

    language.match(/(Markdown|Text)/)
  end    

private
  def pipeline(html)
    context = {
      :asset_root => "http://#{APP_DOMAIN}/images",
      # :base_url   => "#{APP_DOMAIN}"
    }

    pipe = HTML::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      HTML::Pipeline::SanitizationFilter,
      HTML::Pipeline::ImageMaxWidthFilter,
      HTML::Pipeline::EmojiFilter
    ], context.merge(:gfm => true)

    pipe.call(html)[:output].to_s
  end

  def fetch
    begin
      gist = Github::Gists.new.get(@gist_id, client_id: Roughdraft.gh_config['client_id'], client_secret: Roughdraft.gh_config['client_secret'])

      gist.files.each do |file, value|
        if is_allowed value.language.to_s
          value[:rendered] = pipeline value.content.to_s
        end
      end

      REDIS.setex(id, 60, gist.to_hash.to_json.to_s)
      gist.to_hash

    rescue Github::Error::NotFound
      false
    end
  end
end