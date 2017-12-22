# frozen_string_literal: true
require 'db/model.rb'

module Vk
  # Chats
  class Chat < VkInformerTestBase
    has_many :links
    has_many :posts
    has_many :walls, through: :links

    WATCH_LIMIT = 5

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
      return <<~TEXT
        <b>Status</b>: #{ enabled ? 'enabled' : 'disabled' }
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
      telegram.api.send_message(
        chat_id: chat_id, 
        text: text,
        disable_web_page_preview: true,
        parse_mode: parse_mode
      )
    rescue StandardError => e
      Vk::Log.logger.error e.message
    end

  private

    def telegram
      @@client ||= Telegram::Bot::Client.new(Vk::Config::get('tg_token'))
    end
  end
end
