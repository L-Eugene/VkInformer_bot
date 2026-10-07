# frozen_string_literal: true

require 'vk/vk_informer_classes'

module Vk
  # Groups
  class Wall < VkInformerBase
    has_many :cwlinks
    has_many :chats, through: :cwlinks

    validates_uniqueness_of :domain, case_sensitive: false

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
      targets = chats.select(&:enabled?)
      Vk.log.info Vk.t.wall.sending(message: post.message_id, chats: targets.size)
      targets.each { |chat| chat.send_post(post) }
    end

    # Returns { status: :ok | :failed, posts: number of new posts sent }
    def process
      started = Vk.clock
      @sent = 0
      Vk.log.info Vk.t.wall.process(domain: domain)
      return processed(:failed, started) unless (data = hash_load)

      send_new_messages(fresh_messages(data), data.size)
      processed(:ok, started)
    rescue StandardError
      Vk.log_format($ERROR_INFO)
      processed(:failed, started)
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

    def owner_id
      result = domain.scan(%r{^club(\d*)$}).flatten
      return "-#{result.first}" unless result.empty?

      '0'
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

    # Processes watched walls and returns scan statistics:
    # { ok:, failed:, idle: (walls without enabled chats), posts: }
    def self.process
      find_each.each_with_object(Hash.new(0)) do |wall, stats|
        next stats[:idle] += 1 unless wall.watched?

        result = wall.process
        stats[result[:status]] += 1
        stats[:posts] += result[:posts]
      end
    end

    private

    def send_new_messages(records, received)
      Vk.log.info Vk.t.wall.loaded(received: received, new: records.size, last: last_message_id)
      records.each do |msg|
        Vk.log.debug "API message object: #{msg.inspect}"
        send_message(msg)
        update_last [msg]
        @sent += 1
      end
    end

    def processed(status, started)
      time = (Vk.clock - started).round(1)
      if status == :ok
        Vk.log.info Vk.t.wall.done(domain: domain, sent: @sent, time: time)
      else
        Vk.log.error Vk.t.wall.failed(domain: domain, sent: @sent, time: time)
      end
      { status: status, posts: @sent }
    end

    # last message id
    def lmi(records)
      records.max_by { |x| x[:id].to_i }[:id].to_i
    end

    def http_load
      Vk::Connection.instance.conn.post(
        '/method/wall.get',
        domain: domain,
        count: 30,
        v: 5.131,
        owner_id: owner_id,
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

      fresh_messages(data)
    end

    def fresh_messages(data)
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
