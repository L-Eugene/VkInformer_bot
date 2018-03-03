# frozen_string_literal: true

module Vk
  # Sending URL attached to message
  class Link < Attachment
    attr_reader :text

    def initialize(domain, node)
      super

      @text = "[#{node['link']['title']}](#{node['link']['url']})"
    end

    def to_hash
      {
        text: text,
        disable_web_page_preview: false
      }
    end

    def use_method
      :send_message
    end
  end
end
