# frozen_string_literal: true

module Vk
  # Basic class for attachments
  class Attachment
    attr_reader :domain

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
      text.gsub('<br>', "\n").gsub(%r{</?[^>]*>}, '')
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
  end
end
