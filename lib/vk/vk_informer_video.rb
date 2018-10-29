# frozen_string_literal: true

require 'terrapin'
require 'vk/vk_informer_attachment'

module Vk
  # Video attachment
  class Video < Attachment
    attr_reader :title, :description, :vid

    YOUTUBE_DL_PARAMS = [
      '--quiet',
      '--no-continue',
      '--no-playlist',
      '--max-filesize 49m',
      '--output :path',
      ':url'
    ].freeze

    def initialize(domain, node)
      super

      @vid = "#{node[:video][:owner_id]}_#{node[:video][:id]}"
      @title = node[:video][:title]
      @description = node[:video][:description]
    end

    def to_hash
      downloaded? ? video_hash : default_hash
    end

    def use_method
      downloaded? ? :send_video : :send_message
    end

    def result(hash)
      return unless hash.is_a? Hash

      @file_id = hash.dig('result', 'video', 'file_id') if downloaded?
    end

    private

    def download!
      @file = Tempfile.new('vk_informer_video')

      Terrapin::CommandLine
        .new('youtube-dl', YOUTUBE_DL_PARAMS.join(' '))
        .run(path: @file.path, url: video_url)
      true
    rescue StandardError
      @file.unlink
      Vk.log.info t.error.download(message: $ERROR_INFO.message)
      false
    end

    def downloaded?
      @downloaded ||= download!
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

    def video_hash
      {
        video: @file_id || Faraday::UploadIO.new(@file.path, 'video/mp4'),
        caption: "#{domain_prefix domain}\n#{title}",
        parse_mode: 'Markdown'
      }
    end
  end
end
