# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe Vk::Album do
  before :all do
    @obj = Vk::Album.new(
      'x',
      load_json_fixtures(
        "#{File.dirname(__FILE__)}/../../fixtures/vk_informer_attachment/album/hash.json"
      )
    )
  end

  before :each do
    stub_request(:get, %r{\Ahttp://example\.com/}).to_return(status: 200, body: 'image')
  end

  describe 'Basic' do
    it 'should provide needed methods' do
      expect(@obj).to respond_to(:to_hash, :use_method)
    end

    it 'should use send_photo API call' do
      @obj.to_hash
      expect(@obj.use_method).to eq :send_photo
    end

    it 'should fall back to send_message if image download fails' do
      stub_request(:get, %r{\Ahttp://example\.com/}).to_return(status: 404)
      expect(@obj.to_hash).to have_key(:text)
      expect(@obj.use_method).to eq :send_message
    end
  end

  describe 'Hash build' do
    it 'should build result hash' do
      h = @obj.to_hash
      expect(h).to be_instance_of(Hash)
      expect(h).to have_key(:type)
      expect(h[:type]).to eq 'photo'

      expect(h).to have_key(:media)
      expect(h[:media]).to be_a(Faraday::UploadIO)
      expect(h).to have_key(:caption)
    end
  end
end
