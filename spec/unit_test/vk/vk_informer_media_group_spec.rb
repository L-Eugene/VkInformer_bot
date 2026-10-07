# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe Vk::MediaGroup do
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
    @photos = [build_album, build_album]
    @obj = Vk::MediaGroup.new(@photos)
  end

  describe 'Variants' do
    it 'should try URLs, then uploads, then each photo separately' do
      variants = @obj.variants.to_a
      expect(variants.map(&:first)).to eq %i[send_media send_media deliver_each]
      expect(variants[0].last.map { |h| h[:media] }).to all(match(%r{\Ahttp://example\.com/}))
      expect(variants[1].last.map { |h| h[:media] }).to all(be_a(Faraday::UploadIO))
      expect(variants[2].last).to eq @photos
    end

    it 'should not download anything for the first variant' do
      @obj.variants.first
      expect(@download).not_to have_been_made
    end

    it 'should skip upload variant if any download fails' do
      stub_request(:get, %r{\Ahttp://example\.com/}).to_return(status: 404)
      expect(@obj.variants.map(&:first)).to eq %i[send_media deliver_each]
    end
  end

  describe 'Result' do
    it 'should store file_id for each photo' do
      @obj.result(
        'result' => [
          { 'photo' => [{ 'file_id' => 'a' }] },
          { 'photo' => [{ 'file_id' => 'b' }] }
        ]
      )
      expect(@photos.map { |p| p.to_hash[:media] }).to eq %w[a b]
    end

    it 'should ignore missing or non-array results' do
      expect { @obj.result(nil) }.not_to raise_error
      expect { @obj.result(@photos) }.not_to raise_error
      expect { @obj.result('result' => true) }.not_to raise_error
    end
  end
end
