# frozen_string_literal: true

require 'vk/vk_informer_attachment'

module Vk
  # Sending URL attached to message
  class Link < Attachment
    attr_reader :text

    def initialize(domain, node)
      super

      @text = "[#{node['link']['title']}](#{node['link']['url']})"
      @preview = node['link']['image_src'] if node['link'].key? 'image_src'
    end

    def to_hash
      preview? ? to_hash_image : to_hash_text
    end

    def use_method
      preview? ? :send_photo : :send_message
    end

    private

    def preview?
      @preview
    end

    def to_hash_text
      {
        text: text,
        disable_web_page_preview: false
      }
    end

    def to_hash_image
      {
        type: 'photo',
        media: @preview,
        caption: <<~TEXT,
          #{domain_prefix domain}
          #{text}
        TEXT
        parse_mode: 'Markdown'
      }
    end
  end
end
