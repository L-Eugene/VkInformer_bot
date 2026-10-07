# frozen_string_literal: true

module Vk
  # Delivery ladder for attachments sent as a photo:
  # VK URL -> uploaded local copy -> text link.
  # Including class provides to_hash, photo_url and fallback_message.
  module PhotoVariants
    def use_method
      :send_photo
    end

    # Lazy: the image is downloaded only if Telegram rejected the URL
    def variants
      Enumerator.new do |y|
        y << [:send_photo, to_hash]
        upload = uploaded_hash
        y << [:send_photo, upload] if upload
        y << [:send_message, fallback_message]
      end
    end

    # Fresh UploadIO on every call: a consumed IO can not be sent to the next chat
    def uploaded_hash
      path = local_copy(photo_url)
      path && to_hash.merge(media: Faraday::UploadIO.new(path, 'image/jpeg'))
    end

    def result(hash)
      photo = hash.dig('result', 'photo') if hash.is_a?(Hash)
      @file_id = photo.last['file_id'] if photo.is_a?(Array)
    end
  end
end
