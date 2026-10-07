# frozen_string_literal: true

require 'vk/vk_informer_attachment'
require 'vk/vk_informer_photo_variants'

module Vk
  # Photoalbum attachment
  class Album < Attachment
    include PhotoVariants

    attr_reader :url, :media, :title

    def initialize(domain, node)
      super

      alb_id = "#{node[:album][:owner_id]}_#{node[:album][:id]}"
      @url = "https://vk.com/album#{alb_id}"

      @media = get_album_image node[:album][:thumb]

      @title = node[:album][:title]
    end

    def to_hash
      {
        type: 'photo',
        media: @file_id || media,
        caption: "#{domain_prefix domain, :plain} #{title}: #{url}"
      }
    end

    def use_method
      media ? super : :send_message
    end

    def variants
      media ? super : [[:send_message, fallback_message]]
    end

    def photo_url
      media
    end

    def fallback_message
      fallback_link_message(url, title)
    end
  end
end
