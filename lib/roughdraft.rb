module Roughdraft

  def self.github(auth_token = '')
    github = Github.new do |config|
      config.client_id = gh_config['client_id']
      config.client_secret = gh_config['client_secret']
      config.oauth_token = auth_token
    end
  end

  def self.gist_pipeline(html, gist)
    context = {
      :gfm => true,
      :gist => gist,
      :asset_root => "http://#{APP_DOMAIN}/images",
      # :base_url   => "#{APP_DOMAIN}"
      :current_filetype => html.language.to_s
    }

    pipe = HTML::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      HTML::Pipeline::GistFilter,
      HTML::Pipeline::SanitizationFilter,
      HTML::Pipeline::ImageMaxWidthFilter,
      HTML::Pipeline::EmojiFilter
    ], context

    pipe.call(html.content.to_s)[:output].to_xhtml # return XHTML to be compatible with RSS
  end

end