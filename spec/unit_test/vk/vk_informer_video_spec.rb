# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Vk::Video do
  before :all do
    @obj = Vk::Video.new(
      'x',
      load_json_fix(
        File.dirname(__FILE__) + '/../../fixtures/vk_informer_attachment/video/hash.json'
      )
    )
  end

  describe 'Basic' do
    it 'should provide needed methods' do
      expect(@obj).to respond_to(:to_hash, :use_method)
    end

    it 'should use send_message API call' do
      expect(@obj.use_method).to eq :send_message
    end
  end

  describe 'Hash build' do
    it 'should build result hash' do
      h = @obj.to_hash
      expect(h).to be_instance_of(Hash)
      expect(h).to have_key(:text)
      expect(h[:text]).to include '>Текст на русском</a>'
      expect(h[:text]).to include 'href=\'https://vk.com/video-321_123456\''

      expect(h).to have_key(:disable_web_page_preview)
      expect(h[:disable_web_page_preview]).to be false

      expect(h).to have_key(:parse_mode)
      expect(h[:parse_mode]).to eq 'HTML'
    end

    it 'should build result hash with video URL' do
      tempfile = Tempfile.new

      allow(@obj).to receive(:download!) do
        @obj.instance_variable_set(:@file, tempfile)
        true
      end

      h = @obj.to_hash

      expect(h).to be_instance_of(Hash)
      expect(h).to have_key(:video)
      expect(h[:video]).to be_instance_of Faraday::UploadIO

      expect(h).to have_key(:parse_mode)
      expect(h).to have_key(:caption)
    end

    it 'should build result hash with file_id' do
      tempfile = Tempfile.new

      allow(@obj).to receive(:download!) do
        @obj.instance_variable_set(:@file, tempfile)
        true
      end

      @obj.instance_variable_set(:@file_id, 'some_file_id')
      h = @obj.to_hash

      expect(h).to be_instance_of(Hash)
      expect(h).to have_key(:video)
      expect(h[:video]).to eq 'some_file_id'

      expect(h).to have_key(:parse_mode)
      expect(h).to have_key(:caption)
    end
  end
end
