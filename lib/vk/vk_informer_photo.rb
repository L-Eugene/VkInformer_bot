# frozen_string_literal: true

module Vk
  # Photo Attachment
  class Photo < Attachment
    attr_reader :media

    def initialize(domain, node)
      super
      @media = get_album_image node['photo']
    end

    def to_hash
      return nil unless media
      {
        type: 'photo',
        media: media,
        caption: domain_prefix(domain, :plain)
      }
    end

    def use_method
      :send_photo
    end
  end
end
