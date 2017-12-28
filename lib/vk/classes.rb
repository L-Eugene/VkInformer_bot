# frozen_string_literal: true

require 'singleton'

module Vk
  # Single VK post
  class Post
    attr_reader :text, :photo, :message_id, :domain

    def initialize(data, wall)
      @domain = wall.domain

      @text = ["*#{domain}:*\n#{normalize_text(data['text'])}"]
      @photo = []
      @message_id = data['id']

      parse_attachments data
    end

    private

    def normalize_text(text)
      text.gsub('<br>', "\n")
          .gsub(%r{</?[^>]*>}, '')
          .gsub(%r{\[((?:id|club)\d*)\|([^\]]*)\]}, '[\2](https://vk.com/\1)')
          .gsub('_', '\_')
          .gsub('*', '\*')
    end

    def item_album(item)
      imgurl = get_album_image item['album']['thumb']
      return {} if imgurl.nil?

      alburl = "https://vk.com/album#{item['album']['owner_id']}_#{item['album']['aid']}"

      {
        type: 'photo',
        media: imgurl,
        caption: "#{domain}: #{item['album']['title']}: #{alburl}"
      }
    end

    def item_photo(item)
      imgurl = get_album_image item['photo']
      return {} if imgurl.nil?

      {
        type: 'photo',
        media: imgurl,
        caption: domain
      }
    end

    def item_video(item)
      "#{domain}: https://vk.com/video#{item['owner_id']}_#{item['vid']}"
    end

    def get_album_image(a)
      k = %w[src_xxxbig src_xxbig src_xbig src_big src].find { |x| a.key? x }
      k.nil? ? nil : a[k]
    end

    def parse_attachments(data)
      data['attachments'].each do |a|
        case a['type']
        when 'album'
          @photo << item_album(a)
        when 'video'
          @text.unshift item_video(a)
        when 'photo'
          @photo << item_photo(a)
        end
      end
    end
  end

  # Faraday connection singleton
  class Connection
    include Singleton

    attr_reader :conn

    def initialize
      @conn ||= Faraday.new(url: 'https://api.vk.com') do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
