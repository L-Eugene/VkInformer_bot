# frozen_string_literal: true

require 'exceptions/vk_informer_error_base'

module Vk
  # No such group exception
  class NoSuchGroup < Vk::ErrorBase
    private

    def default_message
      t.exception.no_such_group.message
    end

    def default_cmessage
      t.exception.no_such_group.cmessage
    end

    def log_level
      :info
    end
  end

  # Incorrect group exception
  class IncorrectGroup < Vk::ErrorBase
    private

    def default_message
      t.exception.incorrect_group.message(domain: @data&.domain)
    end

    def default_cmessage
      t.exception.incorrect_group.cmessage(domain: @data&.domain)
    end

    def log_level
      :info
    end
  end

  # Too much groups exception
  class TooMuchGroups < Vk::ErrorBase
    private

    def default_message
      t.exception.too_much_groups.message(chat: @chat&.chat_id)
    end

    def default_cmessage
      t.exception.too_much_groups.cmessage
    end

    def log_level
      :info
    end
  end

  # Already watching exception
  class AlreadyWatching < Vk::ErrorBase
    private

    def default_message
      t.exception.already_watching.message(
        chat: @chat&.chat_id,
        domain: @data.domain
      )
    end

    def default_cmessage
      t.exception.already_watching.cmessage(domain: @data.domain)
    end
  end
end
