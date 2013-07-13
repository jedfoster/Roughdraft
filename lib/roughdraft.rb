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

    if html.language.to_s == 'Textile'
      filter = HTML::Pipeline::TextileFilter

    elsif html.language.to_s == 'Haml'
      filter = HTML::Pipeline::HamlFilter

    else
      filter = HTML::Pipeline::MarkdownFilter
    end

    pipe = HTML::Pipeline.new [
      filter,
      HTML::Pipeline::GistFilter,
      HTML::Pipeline::SanitizationFilter,
      HTML::Pipeline::ImageMaxWidthFilter,
      HTML::Pipeline::EmojiFilter
    ], context

    pipe.call(html.content.to_s)[:output].to_xhtml # return XHTML to be compatible with RSS
  end

end