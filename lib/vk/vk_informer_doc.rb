# frozen_string_literal: true

require 'vk/vk_informer_attachment'

module Vk
  # Document attachment
  class Doc < Attachment
    attr_reader :title, :url

    def initialize(domain, node)
      super

      @title = normalize_text node['doc']['title']
      @url = node['doc']['url']
      @ext = node['doc']['ext']
    end

    def to_hash
      Vk.log.info "[#{title}](#{url})"
      return gif_hash if gif?
      {
        text: "[#{title}](#{url})",
        disable_web_page_preview: false
      }
    end

    def result(hash)
      @file_id = hash['document']['file_id'] if gif?
    end

    def gif_hash
      f = Tempfile.new(['vk_informer', '.gif'])
      f.write Vk::Connection.get_file(url)
      {
        document: @file_id || Faraday::UploadIO.new(f.path, 'image/gif'),
        caption: "#{domain_prefix domain}\n#{title}",
        parse_mode: 'Markdown'
      }
    end

    def use_method
      gif? ? :send_doc : :send_message
    end

    private

    def gif?
      @is_gif ||= title.gsub(%r{\?.*$}, '') =~ %r{\.gif$} || @ext == 'gif'
    end
  end
end
