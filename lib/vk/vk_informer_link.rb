# frozen_string_literal: true

require 'vk/vk_informer_attachment'

module Vk
  # Sending URL attached to message
  class Link < Attachment
    attr_reader :text

    def initialize(domain, node)
      super

      @text = "[#{node[:link][:title]}](#{node[:link][:url]})"
      @preview = get_image(node) if node[:link].key? :image_src
    end

    def to_hash
      preview? ? to_hash_image : to_hash_text
    end

    def result(hash)
      return unless hash.is_a? Hash

      return if hash.dig('result', 'photo').nil?

      @file_id = hash.dig('result', 'photo').last['file_id']
    end

    def use_method
      preview? ? :send_photo : :send_message
    end

    private

    def preview?
      @preview
    end

    def get_image(node)
      node[:link][node[:link].key?(:image_big) ? :image_big : :image_src]
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
