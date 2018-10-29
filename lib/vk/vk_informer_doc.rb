# frozen_string_literal: true

require 'tempfile'
require 'vk/vk_informer_attachment'

module Vk
  # Document attachment
  class Doc < Attachment
    attr_reader :title, :url

    def initialize(domain, node)
      super

      @title = normalize_text node[:doc][:title]
      @url = node[:doc][:url]
      @ext = node[:doc][:ext]
    end

    def to_hash
      return gif_hash if gif?

      {
        text: "[#{title}](#{url})",
        disable_web_page_preview: false
      }
    end

    def result(hash)
      return unless hash.is_a? Hash

      @file_id = hash.dig('result', 'document', 'file_id') if gif?
    end

    def use_method
      gif? ? :send_document : :send_message
    end

    private

    def gif_hash
      f = Tempfile.new(['vk_informer', '.gif'])
      f.write Vk::Connection.get_file(url)
      {
        document: @file_id || Faraday::UploadIO.new(f.path, 'image/gif'),
        caption: "#{domain_prefix domain}\n#{title}",
        parse_mode: 'Markdown'
      }
    end

    def gif?
      @gif ||= title.gsub(%r{\?.*$}, '') =~ %r{\.gif$} || @ext == 'gif'
    end
  end
end
