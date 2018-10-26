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

      @file_id = hash['photo'].last['file_id'] if hash
    end
  end
end
