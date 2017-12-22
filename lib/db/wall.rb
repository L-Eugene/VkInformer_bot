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
      return false unless data = hash_load
      update_attribute(:last_message_id, get_lmi(data)) if last_message_id.nil?
      true
    end

  private

    def get_lmi(records)
      records.max_by { |x| x['id'].to_i }['id'].to_i
    end

    def http_load
      Wall.conn.post(
        '/method/wall.get',
         domain: domain,
         count: 20,
         access_token: Vk::Config.get('vk_token')
      )
    rescue Faraday::Error
      log.info "Could not connect to VK.COM. (#{$ERROR_INFO.message})"
      return false
    end

    def hash_load
      return false unless response = http_load
      data = JSON.parse response.body

      return false if data.key? 'error'
      data['response'].shift
      data['response']
    rescue JSON::ParserError
      log.info 'Error while parsing JSON response from VK.COM.'
      log.debug $ERROR_INFO.message
      return false      
    end

    def self.conn
      @@conn ||= Faraday.new(url: 'https://api.vk.com') do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    end

    def log
      Vk::Log.logger
    end
  end
end
