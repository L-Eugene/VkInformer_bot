# frozen_string_literal: true

module Vk
  # Document attachment
  class Doc < Attachment
    attr_reader :title, :url

    def initialize(domain, node)
      super

      @title = node['doc']['title']
      @url = node['doc']['url']
    end

    def to_hash
      return gif_hash if gif?
      {
        text: "[#{title}](#{url})",
        disable_web_page_preview: false
      }
    end

    def gif_hash
      f = Tempfile.new(['vk_informer', '.gif'])
      f.write Vk::Connection.get_file(url)
      {
        document: Faraday::UploadIO.new(f.path, 'image/gif'),
        caption: "#{domain_prefix domain}\n#{title}",
        parse_mode: 'Markdown'
      }
    end

    private

    def gif?
      @is_gif ||= title =~ %r{\.gif$}
    end
  end
end
