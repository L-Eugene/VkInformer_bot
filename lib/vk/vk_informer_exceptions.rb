# frozen_string_literal: true

module Vk
  # No such group exception
  class NoSuchGroup < StandardError
    attr_reader :to_chat

    def initialize
      @to_chat = 'No such group.'
      super('Group not found.')
    end
  end

  # Incorrect group exception
  class IncorrectGroup < StandardError
    attr_reader :to_chat

    def initialize(w)
      @to_chat = "Group https://vk.com/#{w.domain} is invalid."
      super "Error receiving group #{w.domain}"
    end
  end

  # Too much groups exception
  class TooMuchGroups < StandardError
    def message
      'Chat is already watching maximal amount of groups.'
    end
  end

  # Already watching exception
  class AlreadyWatching < StandardError
    attr_reader :to_chat

    def initialize(w)
      @wall = "You are already watching https://vk.com/#{w.domain}"
      super "Chat is already watching group #{w.domain}"
    end
  end
end
