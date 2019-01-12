# frozen_string_literal: true

require 'r18n-core'
require 'r18n-rails-api'

require 'r18n/vk_informer_r18n_filters'

# VK informer module
module Vk
  # Localization singleton
  class Localization
    include Singleton

    attr_reader :object

    def initialize
      @object = R18n.set('ru', File.join(File.dirname(__FILE__), '../../i18n/'))
    end
  end

  def self.t
    Vk::Localization.instance.object.t
  end
end
