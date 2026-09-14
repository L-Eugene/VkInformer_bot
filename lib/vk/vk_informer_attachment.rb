# frozen_string_literal: true

require 'faraday'
require 'tempfile'
require 'uri'

# VK informer namespace
module Vk
  # Basic class for attachments
  class Attachment
    attr_reader :domain

    def self.valid_data?(_data)
      true
    end

    def initialize(domain, node)
      @domain = domain

      Vk.log.debug "Parsing attachment: #{node}"
    end

    def to_hash
      raise Vk.t.classes.undefined
    end

    def use_method
      raise Vk.t.classes.undefined
    end

    def result(_hash)
      nil
    end

    def normalize_title(text)
      text.delete(']')
    end

    def normalize_text(text)
      (text || '').gsub('<br>', "\n").gsub(%r{</?[^>]*>}, '')
        .gsub(%r{\[((?:id|club)\d*)\|([^\]]*)\]}, '[\2](https://vk.com/\1)')
        .gsub('_', '\_').gsub('*', '\*')
    end

    def domain_prefix(domain, type = :markdown)
      d = domain.tr('.', '_')
      dn = normalize_text d

      return "[#{domain}](https://vk.com/#{domain}) ##{dn}" if type == :markdown

      return "https://vk.com/#{domain} ##{d}" if type == :plain

      "<a href='https://vk.com/#{domain}'>#{domain}</a> ##{d}"
    end

    def get_album_image(obj)
      obj[:sizes].max { |a, b| a[:height] <=> b[:height] }[:url]
    end

    def download_url_to_uploadio(url, mime = 'image/jpeg')
      return nil if url.to_s.empty?

      uri = URI.parse(url)
      return nil unless %w[http https].include?(uri.scheme)

      resp = Faraday.get(url)
      return nil unless resp.success?

      file = Tempfile.new(['vk_informer_attachment', ".#{mime_to_ext(mime)}"])
      file.binmode
      file.write(resp.body)
      file.rewind

      Vk.tempfiles ||= []
      Vk.tempfiles << file

      Faraday::UploadIO.new(file.path, mime)
    rescue StandardError
      nil
    end

    def fallback_link_message(url, label = nil)
      label ||= url
      {
        text: "[#{label}](#{url})",
        disable_web_page_preview: false,
        parse_mode: 'Markdown'
      }
    end

    private

    def mime_to_ext(mime)
      return 'jpg' if mime == 'image/jpeg'
      return 'png' if mime == 'image/png'
      return 'gif' if mime == 'image/gif'

      'bin'
    end
  end

  class << self
    attr_accessor :tempfiles

    def cleanup_tempfiles
      Array(tempfiles).each do |file|
        file.close! if file.respond_to?(:close!) && file.respond_to?(:path)
        file.unlink if file.respond_to?(:unlink)
      end

      self.tempfiles = []
    end
  end
end
