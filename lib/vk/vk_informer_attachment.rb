# frozen_string_literal: true

module Vk
  # Basic class for attachments
  class Attachment
    attr_reader :domain

    def initialize(domain, _node)
      @domain = domain
    end

    def to_hash
      raise 'Should be defined in child class'
    end

    def use_method
      raise 'Should be defined in child class'
    end

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

    def get_album_image(a)
      k = %w[1280 807 604 130 75].find { |x| a.key? "photo_#{x}" }
      k.nil? ? nil : a["photo_#{k}"]
    end
  end
end
