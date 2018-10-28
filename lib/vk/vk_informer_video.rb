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

      download!
    end

    def to_hash
      downloaded? ? video_hash : default_hash
    end

    def use_method
      downloaded? ? :send_video : :send_message
    end

    private

    def download!
      @downloaded = false
    end

    def downloaded?
      @downloaded
    end

    def video_url
      "https://vk.com/video#{vid}"
    end

    def default_hash
      {
        text: <<~HTML,
          Video: <a href='#{video_url}'>#{normalize_text title}</a>
          #{normalize_text description}
          #{domain_prefix domain, :html}
        HTML
        disable_web_page_preview: false,
        parse_mode: 'HTML'
      }
    end
  end
end
