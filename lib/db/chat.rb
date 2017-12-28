# frozen_string_literal: true

require 'db/model.rb'

module Vk
  # Chats
  class Chat < VkInformerBase
    has_many :links
    has_many :posts
    has_many :walls, through: :links

    WATCH_LIMIT = 5
    MAX_LENGTH  = 4000

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
      raise Vk::IncorrectGroup, wall unless wall.correct?
      raise Vk::TooMuchGroups if full?
      raise Vk::AlreadyWatching, wall if watching? wall
      walls << wall
    end

    def delete(wall)
      raise Vk::NoSuchGroup if wall.nil?
      walls.delete wall
    end

    def send_message(text, parse_mode = 'Markdown')
      split_message(text).each do |t|
        telegram.api.send_message(
          chat_id: chat_id,
          text: t,
          disable_web_page_preview: true,
          parse_mode: parse_mode
        )
      end
    rescue StandardError
      print_error $ERROR_INFO
    end

    def send_photo(b)
      telegram.api.send_photo(
        chat_id: chat_id,
        photo: b.first[:media],
        caption: b.first[:caption]
      )
    rescue StandardError
      print_error $ERROR_INFO
    end

    def send_photo(b)
      return send_photo b.first if b.size == 1
      telegram.api.send_media_group(chat_id: chat_id, media: b.to_json)
    rescue StandardError
      print_error $ERROR_INFO
    end

    def send_post(post)
      post.photo.in_groups_of(10, false) { |p| send_photo(p) }
      post.text.each { |t| send_message(t) }
    end

    private

    def telegram
      Vk::Tlg.instance.client
    end

    def logger
      Vk::Log.instance.logger
    end

    def print_error(e)
      logger.error e.message
      update!(enabled: false) if e.message.include? "bot was blocked by the user"
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
