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
      update_attribute(:wall_id, wid(data)) if wall_id.nil?
      true
    end

    def send_message(msg)
      post = Vk::Post.new msg, self
      Vk.log.info t.wall.send(message: post.message_id)
      chats.each { |chat| chat.send_post(post) if chat.enabled? }
    end

    def process
      Vk.log.info t.wall.process(domain: domain_escaped)
      records = new_messages
      records.each { |msg| send_msg(msg) }
      update_last records
    end

    def update_last(records = new_messages)
      return if records.empty?

      Vk.log.info t.wall.last(domain: domain_escaped, last: last_value)
      last_value = lmi(records)

      update_attribute(:last_message_id, last_value)
    end

    def domain_escaped
      Vk::Tlg.escape domain
    end

    def self.process
      find_each do |wall|
        if wall.watched?
          wall.process
        else
          wall.update_last
        end
      end
    end

    private

    # last message id
    def lmi(records)
      records.max_by { |x| x[:id].to_i }[:id].to_i
    end

    def wid(records)
      records.first[:owner_id].to_i
    rescue StandardError
      Vk.log.error $ERROR_INFO
      nil
    end

    def http_load
      Vk::Connection.instance.conn.post(
        '/method/wall.get',
        domain: domain,
        count: 30,
        v: 5.36,
        access_token: Vk::Token.best.key
      )
    rescue Faraday::Error
      Vk.log.error t.error.vk_connection(message: $ERROR_INFO.message)
      false
    end

    def parse_json(body)
      data = JSON.parse(body, symbolize_names: true)

      raise t.error.vk_api(error: data[:error][:error_msg]) if data.key? :error

      data[:response][:items]
    end

    def hash_load
      return false unless (response = http_load)

      parse_json(response.body)
    rescue StandardError
      Vk.log.error t.error.json_parse(message: $ERROR_INFO.message)
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
  end
end
