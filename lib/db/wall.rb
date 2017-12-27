# frozen_string_literal: true

module Vk
  # Groups
  class Wall < VkInformerTestBase
    has_many :links
    has_many :chats, through: :links

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
      log.info " ++ Processing #{domain}."
      new_messages.each do |msg|
        post = Vk::Post.new msg
        log.info " ++ Sending #{post.message_id}."
        chats.each { |chat| chat.send_post(post) if chat.enabled? }
        update_attribute(
          :last_message_id,
          [post.message_id, last_message_id].max
        )
      end
    end

    private

    def lmi(records)
      records.max_by { |x| x['id'].to_i }['id'].to_i
    end

    def wid(records)
      records.detect { |x| x['from_id'].to_i == x['to_id'].to_i }['to_id'].to_i
    rescue StandardError
      log.error $ERROR_INFO
      nil
    end

    def http_load
      Vk::Connection.instance.conn.post(
        '/method/wall.get',
        domain: domain,
        count: 20,
        access_token: Vk::Config.instance.options['vk_token']
      )
    rescue Faraday::Error
      log.error "Could not connect to VK.COM. (#{$ERROR_INFO.message})"
      return false
    end

    def hash_load
      return false unless (response = http_load)
      data = JSON.parse response.body

      return false if data.key? 'error'
      data['response'].shift
      data['response']
    rescue JSON::ParserError
      log.error 'Error while parsing JSON response from VK.COM.'
      log.debug $ERROR_INFO.message
      return false
    end

    def new_messages
      return [] unless (data = hash_load)
      data.select  { |msg| msg['id'].to_i > last_message_id }
          .sort_by { |msg| msg['id'].to_i }
    end

    def log
      Vk::Log.instance.logger
    end
  end
end
