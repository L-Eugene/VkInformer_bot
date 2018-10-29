# frozen_string_literal: true

require 'vk/vk_informer_attachment'

module Vk
  # Photo Attachment
  class Photo < Attachment
    attr_reader :media

    def initialize(domain, node)
      super
      @media = get_album_image node[:photo]
    end

    def to_hash
      return nil unless media

      {
        type: 'photo',
        media: @file_id || media,
        caption: domain_prefix(domain, :plain)
      }
    end

    def use_method
      :send_photo
    end

    def result(hash)
      return unless hash.is_a? Hash

      return if hash.dig('result', 'photo').nil?

      @file_id = hash.dig('result', 'photo').last['file_id']
    end
  end
end
