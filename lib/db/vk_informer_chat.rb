# frozen_string_literal: true

require 'db/vk_informer_model'

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
      !wall.nil? && walls.any? { |w| w.domain == wall.domain }
    end

    def status
      kbd = Telegram::Bot::Types::InlineKeyboardMarkup.new
      kbd.inline_keyboard = walls.map(&:keyboard_list)

      Vk.log.debug kbd.inspect

      { text: Vk.t.chat.status(enabled: enabled?), reply_markup: kbd }
    end

    def delete_menu
      kbd = Telegram::Bot::Types::InlineKeyboardMarkup.new
      kbd.inline_keyboard = walls.map(&:keyboard_delete)

      Vk.log.debug kbd.inspect

      { text: Vk.t.chat.delete_menu, reply_markup: kbd }
    end

    def add(wall)
      raise Vk::IncorrectGroup, data: wall, chat: self unless wall.correct?

      raise Vk::TooMuchGroups, chat: self if full?

      raise Vk::AlreadyWatching, data: wall, chat: self if watching? wall

      wall.update_last unless wall.watched?
      walls << wall
      send_text Vk.t.chat.added(domain: wall.domain_escaped)
    end

    def delete(wall)
      raise Vk::NoSuchGroup, chat: self if wall.nil?

      walls.delete wall
      send_text Vk.t.chat.removed(domain: wall.domain_escaped)
    end

    def send_callback_answer(callback, data)
      Vk.tlg.api.answer_callback_query(callback_query_id: callback.id)
      return unless data.key? :update

      Vk.tlg.api.edit_message_reply_markup(
        chat_id: chat_id,
        message_id: callback.message.message_id,
        reply_markup: delete_menu[:reply_markup]
      )
    end

    def send_message(hash, parse_mode = 'Markdown')
      Vk.log.debug hash.inspect

      options = { chat_id: chat_id, parse_mode: parse_mode, disable_web_page_preview: true }.merge(hash)

      do_rescued do
        split_message(hash[:text]).each { |t| Vk.tlg.api.send_message(options.merge(text: t)) }
      end
    end

    def send_text(text, parse_mode = 'Markdown')
      do_rescued { send_message(text: text, parse_mode: parse_mode) }
    end

    def send_photo(hash)
      Vk.log.debug hash.inspect

      do_rescued do
        Vk.tlg.api.send_photo({ chat_id: chat_id, photo: hash[:media], caption: hash[:caption] }.merge(hash))
      end
    end

    def send_media(batch)
      return send_photo batch.first if batch.size == 1

      do_rescued { Vk.tlg.api.send_media_group(chat_id: chat_id, media: batch.to_json) }
    end

    def send_video(video)
      do_rescued { Vk.tlg.api.send_video(video.merge(chat_id: chat_id)) }
    end

    def send_document(doc)
      do_rescued { Vk.tlg.api.send_document(doc.merge(chat_id: chat_id)) }
    end

    def send_post(post)
      Vk.log.info Vk.t.chat.sending(message: post.message_id, chat: chat_id)
      post.data.each do |p|
        Vk.log.debug "Post: #{p.inspect}"
        p.result __send__(p.use_method, p.to_hash)

        Vk.log.debug p.to_hash
      end
    end

    private

    def do_rescued
      attempt ||= 1
      yield
    rescue Telegram::Bot::Exceptions::ResponseError
      parameters = JSON.parse($ERROR_INFO.parameters, symbolize_names: true)
      if parameters.key?(:retry_after) && attempt < 5
        attempt += 1
        Vk.log.info "Need try ##{attempt}. Will try again after #{parameters[:retry_after]}s."
        sleep parameters[:retry_after]
        retry
      else
        print_error $ERROR_INFO
      end
    rescue StandardError
      print_error $ERROR_INFO
    end

    def print_error(err)
      Vk.log_format(err)
      update!(enabled: false) if err.message.include? 'was blocked by the user'
    end

    def split_message(text)
      text.split("\n").each_with_object([+'']) do |str, arr|
        str.length + arr.last.length > MAX_LENGTH ? arr << +"#{str}\n" : arr.last << "#{str}\n"
      end
    end
  end
end
