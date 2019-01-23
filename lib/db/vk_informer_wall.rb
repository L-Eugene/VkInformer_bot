# frozen_string_literal: true

require 'vk/vk_informer_classes'

module Vk
  # Groups
  class Wall < VkInformerBase
    has_many :cwlinks
    has_many :chats, through: :cwlinks

    validates_uniqueness_of :domain

    def watched?
      chats.any?(&:enabled?)
    end

    def correct?
      return false unless (data = hash_load)

      update_attribute(:last_message_id, lmi(data)) if last_message_id.nil?
      true
    end

    def send_message(msg)
      post = Vk::Post.new msg, self
      Vk.log.info Vk.t.wall.sending(message: post.message_id)
      chats.each { |chat| chat.send_post(post) if chat.enabled? }
    end

    def process
      Vk.log.info Vk.t.wall.process(domain: domain)
      records = new_messages
      records.each { |msg| send_message(msg) }
      update_last records
    end

    def update_last(records = new_messages)
      return if records.empty?

      last_value = lmi(records)
      Vk.log.info Vk.t.wall.last(domain: domain_escaped, last: last_value)

      update_attribute(:last_message_id, last_value)
    end

    def domain_escaped
      Vk::Tlg.escape domain
    end

    def keyboard_list
      [
        {
          text: Vk.t.keyboard.domain(domain: domain),
          url: "https://vk.com/#{domain}"
        }
      ]
    end

    def keyboard_delete
      [
        {
          text: Vk.t.keyboard.domain(domain: domain),
          callback_data: { action: "delete #{domain}", update: true }.to_json
        }
      ]
    end

    def self.process
      find_each { |wall| wall.process if wall.watched? }
    end

    private

    # last message id
    def lmi(records)
      records.max_by { |x| x[:id].to_i }[:id].to_i
    end

    def http_load
      Vk::Connection.instance.conn.post(
        '/method/wall.get',
        domain: domain,
        count: 30,
        v: 5.36,
        access_token: Vk::Token.best.key
      )
    end

    def parse_json(body)
      data = JSON.parse(body, symbolize_names: true)

      raise Vk.t.error.vk_api(error: data[:error][:error_msg]) if data.key? :error

      data[:response][:items]
    end

    def hash_load
      parse_json(http_load.body)
    rescue StandardError
      Vk.log.error Vk.t.error.vk_api_parse(message: $ERROR_INFO.message)
      disable_wall if $ERROR_INFO.message.include? 'Access denied'
      false
    end

    def new_messages
      return [] unless (data = hash_load)

      data.select  { |msg| msg[:id].to_i > last_message_id }
          .sort_by { |msg| msg[:id].to_i }
          .map do |msg|
            id = msg[:id]
            msg = msg[:copy_history].last if msg.key?(:copy_history)
            msg[:id] = id
            msg
          end
    end

    def disable_wall
      chats.each do |chat|
        chat.walls.delete(self)
        chat.send_text(Vk.t.chat.denied(domain: domain_escaped)) if chat.enabled?
      end
    end
  end
end
