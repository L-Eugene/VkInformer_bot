# frozen_string_literal: true

module Vk
  # Single VK post
  class Post
    attr_reader :text, :photo, :message_id

    def initialize(data)
      @text = [normalize_text(data['text'])]

      @photo = []

      @message_id = data['id']

      parse_attachments data
    end

    private

    def normalize_text(text)
      text.gsub('<br>', "\n")
          .gsub(%r{</?[^>]*>}, '')
          .gsub(%r{\[((?:id|club)\d*)\|([^\]]*)\]}, '\2:(https://vk.com/\1)')
    end

    def item_album(item)
      imgurl = get_album_image item['thumb']
      return {} if imgurl.nil?

      {
        type: 'photo',
        media: imgurl,
        caption: "#{item['title']}: https://vk.com/album#{item['owner_id']}_#{item['aid']}"
      }
    end

    def item_photo(item)
      imgurl = get_album_image item['photo']
      return {} if imgurl.nil?

      {
        type: 'photo',
        media: imgurl
      }
    end

    def item_video(item)
      "https://vk.com/video#{item['owner_id']}_#{item['vid']}"
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
end
