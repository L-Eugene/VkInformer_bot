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

    def send_message(hash, parse_mode = 'Markdown', attachment = nil)
      Vk.log.debug hash.inspect

      options = { chat_id: chat_id, parse_mode: parse_mode, disable_web_page_preview: true }.merge(hash)

      do_rescued(hash, attachment) do
        split_message(hash[:text]).each { |t| send_message_part(options.merge(text: t)) }
      end
    end

    def send_message_part(message_options)
      Vk.tlg.api.send_message(message_options)
    rescue Telegram::Bot::Exceptions::ResponseError => e
      raise unless webpage_curl_failed?(e) && !message_options[:disable_web_page_preview]

      Vk.log.info 'WEBPAGE_CURL_FAILED while sending message. Retrying without webpage preview.'
      Vk.tlg.api.send_message(message_options.merge(disable_web_page_preview: true))
    end

    def send_text(text, parse_mode = 'Markdown')
      do_rescued { send_message(text: text, parse_mode: parse_mode) }
    end

    def send_photo(hash, attachment = nil)
      Vk.log.debug hash.inspect

      do_rescued(hash, attachment) do
        Vk.tlg.api.send_photo({ chat_id: chat_id, photo: hash[:media], caption: hash[:caption] }.merge(hash))
      end
    end

    def send_media(batch, attachment = nil)
      return send_photo(batch.first, attachment) if batch.size == 1

      do_rescued(batch, attachment) { Vk.tlg.api.send_media_group(chat_id: chat_id, media: batch.to_json) }
    end

    def send_video(video, attachment = nil)
      do_rescued(video, attachment) { Vk.tlg.api.send_video(video.merge(chat_id: chat_id)) }
    end

    def send_document(doc, attachment = nil)
      do_rescued(doc, attachment) { Vk.tlg.api.send_document(doc.merge(chat_id: chat_id)) }
    end

    def send_post(post)
      Vk.log.info Vk.t.chat.sending(message: post.message_id, chat: chat_id)
      post.data.each do |p|
        Vk.log.debug "Post: #{p.inspect}"
        p.result __send__(p.use_method, p.to_hash, p)

        Vk.log.debug p.to_hash
      end
    end

    private

    # rubocop:disable-next Metrics/MethodLength
    def do_rescued(payload = nil, attachment = nil)
      attempt ||= 1
      yield
    rescue Telegram::Bot::Exceptions::ResponseError => e
      params = response_error_parameters(e)
      retry_after = params[:retry_after]
      if retry_after && attempt < 5
        attempt += 1
        Vk.log.info "Need try ##{attempt}. Will try again after #{retry_after}s."
        sleep retry_after
        retry
      elsif webpage_curl_failed?(e)
        dispatch_webpage_curl_failed(e, payload, attachment)
      else
        print_error e
      end
    rescue StandardError => e
      print_error e
    end

    def dispatch_webpage_curl_failed(error, payload, attachment)
      fallback = attachment.respond_to?(:fallback_for) ? attachment.fallback_for(error, payload) : nil
      dispatch_fallback(fallback, payload, attachment)
    end

    def dispatch_fallback(fallback, payload, attachment)
      return dispatch_url_message(payload, attachment) unless fallback.is_a?(Hash)

      return send_message(fallback) if fallback.key?(:text)
      return send_photo(fallback, attachment) if fallback[:type].to_s == 'photo'

      dispatch_url_message(payload, attachment)
    rescue StandardError => e
      print_error e
    end

    def dispatch_url_message(payload, attachment)
      media = payload.is_a?(Hash) ? (payload[:media] || payload['media'] || payload[:url]) : nil
      return unless media.to_s.match?(%r{^https?://})

      if attachment.respond_to?(:fallback_link_message)
        send_message(attachment.fallback_link_message(media, nil))
      else
        send_message(text: "[#{media}](#{media})", parse_mode: 'Markdown', disable_web_page_preview: false)
      end
    end

    def response_error_parameters(error)
      parsed = parameters_from_exception(error)
      return parsed unless parsed.empty?

      parameters_from_response(error)
    rescue StandardError
      {}
    end

    def parameters_from_exception(error)
      return {} unless error.respond_to?(:parameters)

      parsed = JSON.parse(error.parameters, symbolize_names: true)
      parsed.is_a?(Hash) ? parsed : {}
    rescue StandardError
      {}
    end

    def parameters_from_response(error)
      response = error.respond_to?(:response) ? error.response : nil
      return {} unless response.respond_to?(:body)

      payload = JSON.parse(response.body, symbolize_names: true)
      params = payload[:parameters] || payload['parameters']
      params.is_a?(Hash) ? params : {}
    rescue StandardError
      {}
    end

    def webpage_curl_failed?(error)
      return false unless error.respond_to?(:response)
      return false unless error.response.respond_to?(:body)

      body = error.response.body
      return false if body.to_s.empty?

      payload = JSON.parse(body)
      description = payload['description'] || payload[:description]
      description.to_s.include?('WEBPAGE_CURL_FAILED')
    rescue StandardError
      false
    end

    def print_error(error)
      Vk.log_format(error)
      update!(enabled: false) if error.message.include? 'was blocked by the user'
    end

    def split_message(text)
      text.split("\n").each_with_object([+'']) do |str, arr|
        str.length + arr.last.length > MAX_LENGTH ? arr << +"#{str}\n" : arr.last << "#{str}\n"
      end
    end
  end
end
