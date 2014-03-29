module Roughdraft

  def self.gist_pipeline(html, gist)
    context = {
      :gfm => true,
      :gist => gist,
      :asset_root => "http://#{RoughdraftApp::APP_DOMAIN}/images",
      # :base_url   => "#{RoughdraftApp::APP_DOMAIN}"
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

  def self.gist_base_regex
    '(?:/)?([\w-]+)?/([\w]+)(?:-.)*'
  end
end
