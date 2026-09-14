# frozen_string_literal: true

require 'vk/vk_informer_attachment'

module Vk
  # Photo Attachment
  class Photo < Attachment
    attr_reader :media

    def initialize(domain, node)
      super
      @media = get_album_image node[:photo]
      @upload_io = nil
      @downloaded = false
    end

    def to_hash
      return nil unless media

      @upload_io = download_url_to_uploadio(media, 'image/jpeg')
      if @upload_io
        {
          type: 'photo',
          media: @file_id || @upload_io,
          caption: domain_prefix(domain, :plain)
        }
      else
        fallback_link_message(media, domain)
      end
    end

    def use_method
      @upload_io ? :send_photo : :send_message
    end

    def result(hash)
      return unless hash.is_a? Hash

      return if hash.dig('result', 'photo').nil?

      @file_id = hash.dig('result', 'photo').last['file_id']
    end
  end
end
