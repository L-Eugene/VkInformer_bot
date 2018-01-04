# frozen_string_literal: true

require 'singleton'

module Vk
  # Single VK post
  class Post
    attr_reader :text, :photo, :message_id, :domain

    def initialize(data, wall)
      @domain = wall.domain

      @text = [item_text(data)]
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

      alb_id = "#{item['album']['owner_id']}_#{item['album']['aid']}"
      alburl = "https://vk.com/album#{alb_id}"

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
      vid = "#{item['video']['owner_id']}_#{item['video']['vid']}"

      {
        text: <<~HTML,
          <b>#{domain}</b>:
          <a href="https://vk.com/video#{vid}">#{normalize_text(item['video']['title'])}</a>
           #{normalize_text(item['video']['description'])}
        HTML
        disable_web_page_preview: false,
        parse_mode: 'HTML'
      }
    end

    def item_link(item)
      {
        text: "[#{item['link']['title']}](#{item['link']['url']})",
        disable_web_page_preview: false
      }
    end

    def item_text(item)
      {
        text: "*#{domain}:*\n#{normalize_text(item['text'])}"
      }
    end

    def get_album_image(a)
      k = %w[src_xxxbig src_xxbig src_xbig src_big src].find { |x| a.key? x }
      k.nil? ? nil : a[k]
    end

    def parse_attachments(data)
      return unless data.key? 'attachments'
      data['attachments'].each do |a|
        meth = "parse_#{a['type']}"
        supported = respond_to? meth.to_sym, true
        send(meth, a) if supported
        logger.info "Unsupported attachment #{a['type']}" unless supported
      end
    end

    def parse_album(a)
      @photo << item_album(a)
    end

    def parse_video(a)
      @text.unshift item_video(a)
    end

    def parse_photo(a)
      @photo << item_photo(a)
    end

    def parse_link(a)
      @text.unshift item_link(a)
    end

    def logger
      Vk::Log.instance.logger
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
