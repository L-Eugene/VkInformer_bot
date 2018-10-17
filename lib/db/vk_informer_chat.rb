# frozen_string_literal: true

require 'db/vk_informer_model.rb'

module Vk
  # Chats
  class Chat < VkInformerBase
    has_many :cwlinks
    has_many :walls, through: :cwlinks

    validates :chat_id, numericality: { only_integer: true }

    # Maximum walls can be watched in one chat
    WATCH_LIMIT = 10
    # Maximal telegram message length
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
      raise Vk::IncorrectGroup, wall unless wall.correct?
      raise Vk::TooMuchGroups if full?
      raise Vk::AlreadyWatching, wall if watching? wall
      walls << wall
    end

    def delete(wall)
      raise Vk::NoSuchGroup if wall.nil?
      walls.delete wall
    end

    def send_message(hash, parse_mode = 'Markdown')
      options = {
        chat_id: chat_id,
        parse_mode: parse_mode,
        disable_web_page_preview: true
      }.merge(hash)
      split_message(hash[:text]).each do |t|
        Vk.tlg.api.send_message(options.merge(text: t))
      end
    rescue StandardError
      print_error $ERROR_INFO
    end

    def send_text(text, parse_mode = 'Markdown')
      send_message(text: text, parse_mode: parse_mode)
    end

    def send_photo(hash)
      Vk.tlg.api.send_photo({
        chat_id: chat_id,
        photo: hash[:media],
        caption: hash[:caption]
      }.merge(hash))
    rescue StandardError
      print_error $ERROR_INFO
    end

    def send_media(b)
      return send_photo b.first if b.size == 1
      Vk.tlg.api.send_media_group(chat_id: chat_id, media: b.to_json)
    rescue StandardError
      print_error $ERROR_INFO
    end

    def send_doc(d)
      Vk.tlg.api.send_document(d.merge(chat_id: chat_id))
    rescue StandardError
      print_error $ERROR_INFO
    end

    def send_post(post)
      Vk.log.info "Sending #{post.message_id} to #{chat_id}"
      post.data.each do |p|
        response = send(p.use_method, p.to_hash)
        response = response['result'] if response.is_a? Hash
        p.result response
      end
    end

    private

    def print_error(e)
      Vk.log.error e.message
      Vk.log.error e.backtrace.join("\n")
      update!(enabled: false) if e.message.include? 'was blocked by the user'
    end

    def split_message(text)
      result = []
      s = ''
      text.split("\n").each do |p|
        result << s if s.length + p.length > MAX_LENGTH
        s = (s.length + p.length) > MAX_LENGTH ? p : "#{s}\n#{p}"
      end
      result << s unless s.empty?
      result
    end
  end
end
