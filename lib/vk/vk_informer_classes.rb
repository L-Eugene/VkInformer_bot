# frozen_string_literal: true

require 'singleton'
require 'faraday_middleware'

module Vk
  # Single VK post
  class Post
    attr_reader :text, :photo, :docs, :message_id, :domain

    def initialize(data, wall)
      @domain = wall.domain

      @text = [item_text(data)]
      @photo = []
      @docs = []
      @message_id = data['id']

      parse_attachments data
    end

    private

    def normalize_text(text)
      text.gsub('<br>', "\n").gsub(%r{</?[^>]*>}, '')
          .gsub(%r{\[((?:id|club)\d*)\|([^\]]*)\]}, '[\2](https://vk.com/\1)')
          .gsub('_', '\_').gsub('*', '\*')
    end

    def domain_prefix(domain, type = :markdown)
      d = normalize_text domain
      return "[https://vk.com/#{domain}](#{domain}) ##{d}" if type == :markdown
      return "https://vk.com/#{domain} ##{domain}" if type == :plain
      "<a href='https://vk.com/#{domain}'>#{domain}</a> ##{domain}"
    end

    def item_album(item)
      return {} unless (imgurl = get_album_image item['album']['thumb'])

      alb_id = "#{item['album']['owner_id']}_#{item['album']['aid']}"
      alburl = "https://vk.com/album#{alb_id}"
      tag = domain_prefix(domain, :plain)

      {
        type: 'photo', media: imgurl,
        caption: "#{tag} #{item['album']['title']}: #{alburl}"
      }
    end

    def item_photo(item)
      return {} unless (imgurl = get_album_image item['photo'])

      { type: 'photo', media: imgurl, caption: domain_prefix(domain, :plain) }
    end

    def item_video(item)
      vid = "#{item['video']['owner_id']}_#{item['video']['vid']}"

      {
        text: <<~HTML,
          <b>#{domain_prefix domain, :html}</b>:
          <a href="https://vk.com/video#{vid}">#{normalize_text(item['video']['title'])}</a>
           #{normalize_text(item['video']['description'])}
        HTML
        disable_web_page_preview: false, parse_mode: 'HTML'
      }
    end

    def item_link(item)
      {
        text: "[#{item['link']['title']}](#{item['link']['url']})",
        disable_web_page_preview: false
      }
    end

    def item_doc_gif(item)
      f = Tempfile.new(['vk_informer', '.gif'])
      f.write Vk::Connection.get_file(item['doc']['url'])
      {
        document: Faraday::UploadIO.new(f.path, 'image/gif'),
        caption: "#{domain_prefix(domain)}\n#{item['doc']['title']}",
        parse_mode: 'Markdown'
      }
    end

    def item_doc(item)
      {
        text: "[#{item['doc']['title']}](#{item['doc']['url']})",
        disable_web_page_preview: false
      }
    end

    def item_text(item)
      { text: "#{domain_prefix domain}:\n#{normalize_text(item['text'])}" }
    end

    def get_album_image(a)
      k = %w[src_xxxbig src_xxbig src_xbig src_big src].find { |x| a.key? x }
      k.nil? ? nil : a[k]
    end

    def parse_attachments(data)
      return unless data.key? 'attachments'
      data['attachments'].each do |a|
        meth = "parse_#{a['type']}"
        send(meth, a) if (supported = respond_to? meth.to_sym, true)
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

    def parse_doc(a)
      return @docs << item_doc_gif(a) if a['doc']['title'] =~ %r{\.gif$}
      @text.unshift item_doc(a)
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
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.adapter Faraday.default_adapter
      end
    end

    def self.get_file(url)
      instance.conn.get(url).body
    end
  end
end
