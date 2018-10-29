# frozen_string_literal: true

module Vk
  # Pack of photos
  class MediaGroup < Attachment
    attr_reader :photos

    def initialize(photos)
      @photos = photos
    end

    def to_hash
      photos.map(&:to_hash)
    end

    def use_method
      :send_media
    end

    def result(hash)
      hash = hash['result']
      return photos.first.result hash unless hash.is_a? Array

      hash.each_with_index do |file, index|
        photos[index].result result: file
      end
    end
  end
end
