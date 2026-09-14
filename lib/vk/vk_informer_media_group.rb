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

    # URLs -> uploaded copies (only if every photo downloaded) -> each photo on its own ladder
    def variants
      Enumerator.new do |y|
        y << [:send_media, to_hash]
        uploads = photos.map(&:uploaded_hash)
        y << [:send_media, uploads] if uploads.all?
        y << [:deliver_each, photos]
      end
    end

    def result(hash)
      messages = hash['result'] if hash.is_a?(Hash)
      return unless messages.is_a?(Array)

      messages.zip(photos) { |message, photo| photo&.result('result' => message) }
    end
  end
end
