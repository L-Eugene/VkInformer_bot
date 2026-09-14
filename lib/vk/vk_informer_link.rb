# frozen_string_literal: true

require 'vk/vk_informer_attachment'
require 'vk/vk_informer_photo_variants'

module Vk
  # Sending URL attached to message
  class Link < Attachment
    include PhotoVariants

    attr_reader :text

    def initialize(domain, node)
      super

      title = (node[:link][:title] || '').empty? ? node[:link][:url] : node[:link][:title]

      @text = "[#{title}](#{node[:link][:url]})"
      @preview = get_album_image(node[:link][:photo]) if node[:link].key? :photo
    end

    def to_hash
      preview? ? to_hash_image : to_hash_text
    end

    def use_method
      preview? ? super : :send_message
    end

    def variants
      preview? ? super : [[:send_message, to_hash_text]]
    end

    def photo_url
      @preview
    end

    def fallback_message
      to_hash_text
    end

    private

    def preview?
      !@preview.nil?
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
        media: @file_id || @preview,
        caption: <<~TEXT,
          #{domain_prefix domain}
          #{text}
        TEXT
        parse_mode: 'Markdown'
      }
    end
  end
end
