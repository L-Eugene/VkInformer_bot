# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe Vk::Album do
  def build_album
    Vk::Album.new(
      'x',
      load_json_fixtures(
        "#{File.dirname(__FILE__)}/../../fixtures/vk_informer_attachment/album/hash.json"
      )
    )
  end

  before :each do
    @download = stub_request(:get, %r{\Ahttp://example\.com/}).to_return(status: 200, body: 'image')
    @obj = build_album
  end

  describe 'Basic' do
    it 'should provide needed methods' do
      expect(@obj).to respond_to(:to_hash, :use_method, :variants)
    end

    it 'should use send_photo API call regardless of call order' do
      expect(@obj.use_method).to eq :send_photo
      @obj.to_hash
      expect(@obj.use_method).to eq :send_photo
    end
  end

  describe 'Hash build' do
    it 'should build result hash' do
      h = @obj.to_hash
      expect(h).to be_instance_of(Hash)
      expect(h).to have_key(:type)
      expect(h[:type]).to eq 'photo'

      expect(h).to have_key(:media)
      expect(h[:media]).to match %r{\Ahttp://example\.com/}
      expect(h).to have_key(:caption)
    end

    it 'should use file_id once photo was sent' do
      @obj.result('result' => { 'photo' => [{ 'file_id' => 'abc' }] })
      expect(@obj.to_hash[:media]).to eq 'abc'
    end
  end

  describe 'Variants' do
    it 'should try URL first without downloading' do
      expect(@obj.variants.first).to eq [:send_photo, @obj.to_hash]
      expect(@download).not_to have_been_made
    end

    it 'should fall back to upload and then to album link' do
      variants = @obj.variants.to_a
      expect(variants.map(&:first)).to eq %i[send_photo send_photo send_message]
      expect(variants[1].last[:media]).to be_a(Faraday::UploadIO)
      expect(variants[2].last[:text]).to include 'https://vk.com/album'
    end

    it 'should download image only once' do
      2.times { @obj.variants.to_a }
      expect(@download).to have_been_made.once
    end

    it 'should skip upload variant if download fails' do
      stub_request(:get, %r{\Ahttp://example\.com/}).to_return(status: 404)
      expect(build_album.variants.map(&:first)).to eq %i[send_photo send_message]
    end
  end
end
