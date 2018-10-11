# frozen_string_literal: true

require 'vk/vk_informer_attachment'

module Vk
  # Video attachment
  class Video < Attachment
    attr_reader :title, :description, :vid

    def initialize(domain, node)
      super

      @vid = "#{node[:video][:owner_id]}_#{node[:video][:id]}"
      @title = node[:video][:title]
      @description = node[:video][:description]
    end

    def to_hash
      {
        text: <<~HTML,
          Video: <a href='https://vk.com/video#{vid}'>#{normalize_text title}</a>
          #{normalize_text description}
          #{domain_prefix domain, :html}
        HTML
        disable_web_page_preview: false,
        parse_mode: 'HTML'
      }
    end

    def use_method
      :send_message
    end
  end
end
