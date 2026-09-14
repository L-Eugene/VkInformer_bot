# frozen_string_literal: true

require 'vk/vk_informer_attachment'
require 'vk/vk_informer_photo_variants'

module Vk
  # Photo Attachment
  class Photo < Attachment
    include PhotoVariants

    attr_reader :media

    def initialize(domain, node)
      super
      @media = get_album_image node[:photo]
    end

    def to_hash
      {
        type: 'photo',
        media: @file_id || media,
        caption: domain_prefix(domain, :plain)
      }
    end

    def photo_url
      media
    end

    def fallback_message
      fallback_link_message(media, domain)
    end
  end
end
