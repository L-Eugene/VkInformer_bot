# frozen_string_literal: true

module Vk
  # No such group exception
  class NoSuchGroup < StandardError
    def message
      'Group not found'
    end

    def to_chat
      'No such group.'
    end
  end

  # Incorrect group exception
  class IncorrectGroup < StandardError
    attr_reader :wall
    def initialize(w)
      @wall = w
      super "Error receiving group #{wall.domain}"
    end

    def to_chat
      "Group https://vk.com/#{wall.domain} is invalid."
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
    attr_reader :wall
    def initialize(w)
      @wall = w
      super "Chat is already watching group #{wall.domain}"
    end

    def to_chat
      "You are already watching https://vk.com/#{wall.domain}"
    end
  end
end
