# frozen_string_literal: true

require 'vk/vk_informer_attachment'

module Vk
  # Photoalbum attachment
  class Album < Attachment
    attr_reader :url, :media, :title

    def initialize(domain, node)
      super

      alb_id = "#{node[:album][:owner_id]}_#{node[:album][:id]}"
      @url = "https://vk.com/album#{alb_id}"

      @media = get_album_image node[:album][:thumb]

      @title = node[:album][:title]
      @upload_io = nil
    end

    def to_hash
      return nil unless media

      @upload_io = download_url_to_uploadio(media, 'image/jpeg')
      if @upload_io
        {
          type: 'photo',
          media: @file_id || @upload_io,
          caption: "#{domain_prefix domain, :plain} #{title}: #{url}"
        }
      else
        fallback_link_message(url, title)
      end
    end

    def use_method
      @upload_io ? :send_photo : :send_message
    end

    def result(hash)
      return unless hash.is_a? Hash

      @file_id = hash.dig('result', 'photo').last['file_id']
    end
  end
end
