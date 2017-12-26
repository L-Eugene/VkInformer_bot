# frozen_string_literal: true

require 'db/model.rb'

module Vk
  # Chats
  class Chat < VkInformerTestBase
    has_many :links
    has_many :posts
    has_many :walls, through: :links

    WATCH_LIMIT = 5
    MAX_LENGTH  = 4080

    after_create :init

    def init
      update_attribute(:enabled, true) if enabled.nil?
    end

    def full?
      walls.size >= WATCH_LIMIT
    end

    def watching?(wall)
      return false if wall.nil?
      walls.any? { |w| w.domain == wall.domain }
    end

    def status
      <<~TEXT
        <b>Status</b>: #{enabled ? 'enabled' : 'disabled'}
        <b>Watching</b>:
        #{walls.pluck(:domain).join("\n")}
      TEXT
    end

    def add(wall)
      raise Vk::IncorrectGroup.new(wall) unless wall.correct?
      raise Vk::TooMuchGroups if full?
      raise Vk::AlreadyWatching.new(wall) if watching? wall
      walls << wall
    end

    def delete(wall)
      raise Vk::NoSuchGroup if wall.nil?
      walls.delete wall
    end

    def send_message(text, parse_mode = nil)
      split_message(text).each do |t|
        telegram.api.send_message(
          chat_id: chat_id,
          text: t,
          disable_web_page_preview: true,
          parse_mode: parse_mode
        )
      end
    rescue StandardError => e
      Vk::Log.instance.logger.error e.message
    end

    def send_photo(b)
      if b.size > 1
        telegram.api.send_media_group(chat_id: chat_id, media: b.to_json)
      else
        telegram.api.send_photo(
          chat_id: chat_id,
          photo: b.first[:media]
        )
      end
    end

    def send_post(post)
      post.photo.in_groups_of(10, false) { |p| send_photo(p) }
      post.text.each { |t| send_message(t) }
    end

    private

    def telegram
      Vk::Tlg.instance.client
    end

    def split_message(text)
      result = []
      s = ''
      text.split("\n").each do |p|
        result << s if s.length + p.length > 4080
        s = (s.length + p.length) > 4080 ? p : "#{s}\n#{p}"
      end
      result << s unless s.empty?
      result
    end
  end
end
