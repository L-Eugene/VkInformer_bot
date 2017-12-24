# frozen_string_literal: true

require 'active_record'

module Vk
  # Default active record class
  class VkInformerTestBase < ActiveRecord::Base
    self.abstract_class = true

    establish_connection(Vk::Config.get('database'))
    @logger = Vk::Log.logger
  end

  ActiveSupport::LogSubscriber.colorize_logging = false
end

require 'db/chat.rb'
require 'db/wall.rb'
require 'db/link.rb'
