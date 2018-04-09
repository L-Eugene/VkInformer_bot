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

    def process
      Vk.log.info " ++ Processing #{domain}."
      records = new_messages
      records.each do |msg|
        post = Vk::Post.new msg, self
        Vk.log.info " +++ Sending #{post.message_id}."
        chats.each { |chat| chat.send_post(post) if chat.enabled? }
      end
      update_last records
    end

    def update_last(records = new_messages)
      return if records.empty?
      last_value = lmi(records)
      Vk.log.info " +++ Updating last for #{domain} (#{last_value})"
      update_attribute(:last_message_id, last_value)
    end

    private

    def lmi(records)
      records.max_by { |x| x['id'].to_i }['id'].to_i
    end

    def wid(records)
      records.detect { |x| x['from_id'].to_i == x['to_id'].to_i }['to_id'].to_i
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
      Vk.log.error "Could not connect to VK.COM. (#{$ERROR_INFO.message})"
      false
    end

    def hash_load
      return false unless (response = http_load)
      data = JSON.parse response.body

      raise "VK API: #{data['error']['error_msg']}" if data.key? 'error'
      data['response']['items']
    rescue StandardError
      Vk.log.error 'Error while parsing JSON response from VK.COM.'
      Vk.log.error $ERROR_INFO.message
      false
    end

    def new_messages
      return [] unless (data = hash_load)
      data.select  { |msg| msg['id'].to_i > last_message_id }
          .sort_by { |msg| msg['id'].to_i }
          .map do |msg|
            id = msg['id']
            msg = msg['copy_history'].last if msg.key?('copy_history')
            msg['id'] = id
            msg
          end
    end
  end
end
