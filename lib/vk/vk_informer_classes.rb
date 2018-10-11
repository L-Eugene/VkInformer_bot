# frozen_string_literal: true

require 'singleton'
require 'faraday_middleware'

Dir["#{File.dirname(__FILE__)}/*rb"].each { |f| require f }

module Vk
  # Single VK post
  class Post
    attr_reader :data, :message_id, :domain

    def initialize(node, wall)
      @domain = wall.domain

      @message_id = node[:id]

      @data = [Vk::Textual.new(domain, node)]
      parse_attachments node
      compact_photos
    end

    private

    def parse_attachments(node)
      return unless node.key? :attachments
      node[:attachments].each do |a|
        supported = valid_attachment? a[:type]
        data << attachment(a[:type]).new(domain, a) if supported
        Vk.log.info "Unsupported attachment #{a[:type]}" unless supported
      end
    end

    def valid_attachment?(name)
      name = name.downcase.capitalize
      Vk.const_defined?(name) && Vk.const_get(name).is_a?(Class)
    end

    def compact_photos
      t = @data.select { |p| p.use_method == :send_photo }
               .in_groups_of(10, false).map do |block|
        block.size > 1 ? Vk::MediaGroup.new(block) : block.first
      end
      @data.delete_if { |p| p.use_method == :send_photo }
      @data.unshift(*t)
    end

    def attachment(name)
      name = name.downcase.capitalize
      Vk.const_get(name) if Vk.const_defined?(name)
    end
  end

  # Faraday connection singleton
  class Connection
    include Singleton

    attr_reader :conn

    def initialize
      @conn ||= Faraday.new(url: 'https://api.vk.com') do |faraday|
        faraday.request :url_encoded
        faraday.use FaradayMiddleware::FollowRedirects
        faraday.adapter Faraday.default_adapter
      end
    end

    def self.get_file(url)
      instance.conn.get(url).body
    end
  end
end
