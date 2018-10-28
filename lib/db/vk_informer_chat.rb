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
      t.chat.status(
        enabled: enabled? ? 'enabled' : 'disabled',
        list: walls.pluck(:domain).join("\n")
      )
    end

    def add(wall)
      raise Vk::IncorrectGroup, data: wall, chat: self unless wall.correct?

      raise Vk::TooMuchGroups, chat: self if full?

      raise Vk::AlreadyWatching, data: wall, chat: self if watching? wall

      walls << wall
      send_text t.chat.added(domain: wall.domain_escaped)
    end

    def delete(wall)
      raise Vk::NoSuchGroup, chat: self if wall.nil?

      walls.delete wall
      send_text t.chat.delete(domain: wall.domain_escaped)
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

    def send_media(batch)
      return send_photo batch.first if batch.size == 1

      Vk.tlg.api.send_media_group(chat_id: chat_id, media: batch.to_json)
    rescue StandardError
      print_error $ERROR_INFO
    end

    def send_doc(doc)
      Vk.tlg.api.send_document(doc.merge(chat_id: chat_id))
    rescue StandardError
      print_error $ERROR_INFO
    end

    def send_post(post)
      Vk.log.info t.chat.sending(message: post.message_id, chat: chat_id)
      post.data.each { |p| p.result send(p.use_method, p.to_hash) }
    end

    private

    def print_error(err)
      Vk.log.error err.message
      Vk.log.error err.backtrace.join("\n")
      update!(enabled: false) if err.message.include? 'was blocked by the user'
    end

    def split_message(text)
      text.split("\n").each_with_object([+'']) do |str, arr|
        if str.length + arr.last.length > MAX_LENGTH
          arr << +"#{str}\n"
        else
          arr.last << "#{str}\n"
        end
      end
    end
  end
end
