# frozen_string_literal: true

module Vk
  # Pack of photos
  class MediaGroup < Attachment
    attr_reader :photos

    # rubocop:disable-next Lint/MissingSuper
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
      returned = hash['result'] || hash[:result]
      return unless returned

      return photos.first.result(returned) unless returned.is_a?(Array)

      returned.each_with_index do |file, index|
        photo = photos[index]
        next unless photo

        photo.result('result' => file)
      end
    end
  end
end
