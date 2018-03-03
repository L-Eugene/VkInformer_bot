# frozen_string_literal: true

require 'singleton'
require 'faraday_middleware'

module Vk
  # Single VK post
  class Post
    attr_reader :text, :photo, :docs, :message_id, :domain

    def initialize(data, wall)
      @domain = wall.domain

      @text = [Vk::Textual.new(domain, data).to_hash]
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

    def parse_attachments(data)
      return unless data.key? 'attachments'
      data['attachments'].each do |a|
        meth = "parse_#{a['type']}"
        send(meth, a) if (supported = respond_to? meth.to_sym, true)
        logger.info "Unsupported attachment #{a['type']}" unless supported
      end
    end

    def parse_album(a)
      @photo << Vk::Album.new(domain, a).to_hash
    end

    def parse_video(a)
      @text.unshift Vk::Video.new(domain, a).to_hash
    end

    def parse_photo(a)
      @photo << Vk::Photo.new(domain, a).to_hash
    end

    def parse_link(a)
      @text.unshift Vk::WebLink.new(domain, a).to_hash
    end

    def parse_doc(a)
      t = Vk::Doc.new(domain, a).to_hash
      return @docs << t if a['doc']['title'] =~ %r{\.gif$}
      @text.unshift t
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
