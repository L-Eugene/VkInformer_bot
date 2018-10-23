# frozen_string_literal: true

require 'exceptions/vk_informer_error_base'

module Vk
  # No such group exception
  class NoSuchGroup < Vk::ErrorBase
    private

    def default_message
      'Group not found'
    end

    def default_cmessage
      'No such group'
    end

    def log_level
      :info
    end
  end

  # Incorrect group exception
  class IncorrectGroup < Vk::ErrorBase
    private

    def default_message
      "Error receiving group #{@data&.domain}"
    end

    def default_cmessage
      "Group https://vk.com/#{@data&.domain} is invalid."
    end

    def log_level
      :info
    end
  end

  # Too much groups exception
  class TooMuchGroups < Vk::ErrorBase
    private

    def default_message
      "Chat #{@chat&.chat_id} is already watching maximal amount of groups."
    end

    def default_cmessage
      'Chat is already watching maximal amount of groups.'
    end

    def log_level
      :info
    end
  end

  # Already watching exception
  class AlreadyWatching < Vk::ErrorBase
    private

    def default_message
      "Chat #{@chat&.chat_id} is already watching group #{@data.domain}"
    end

    def default_cmessage
      "You are already watching https://vk.com/#{@data.domain}"
    end
  end
end
