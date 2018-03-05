# frozen_string_literal: true

require 'vk/vk_informer_attachment'

module Vk
  # Video attachment
  class Video < Attachment
    attr_reader :title, :description, :vid

    def initialize(domain, node)
      super

      @vid = "#{node['video']['owner_id']}_#{node['video']['id']}"
      @title = item['video']['title']
      @description = item['video']['description']
    end

    def to_hash
      {
        text: <<~HTML,
          <b>#{domain_prefix domain, :html}</b>:
          <a href="https://vk.com/video#{vid}">#{normalize_text item['video']['title']}</a>
           #{normalize_text item['video']['description']}
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
