# frozen_string_literal: true

require 'vk/vk_informer_attachment'

module Vk
  # Photoalbum attachment
  class Album < Attachment
    attr_reader :url, :media, :title

    def initialize(domain, node)
      super

      alb_id = "#{node['album']['owner_id']}_#{node['album']['id']}"
      @url = "https://vk.com/album#{alb_id}"

      @media = get_album_image node['album']['thumb']

      @title = node['album']['title']
    end

    def to_hash
      return nil unless media
      {
        type: 'photo',
        media: media,
        caption: "#{domain_prefix domain, :plain} #{title}: #{url}"
      }
    end

    def use_method
      :send_photo
    end
  end
end
