# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe Vk::Chat do
  describe 'Basic' do
    before :each do
      @chat = FactoryBot.create(:chat)
    end

    it 'should provide needed attributes' do
      # Database fields
      expect(@chat).to respond_to(:id, :chat_id, :enabled)

      # Relations
      expect(@chat).to respond_to(:cwlinks, :walls)
    end

    it 'should enable chat by default' do
      expect(@chat.enabled?).to be true
    end

    it 'should split long messages right' do
      expect(@chat.__send__(:split_message, '123')).to contain_exactly("123\n")

      long_message = 'x' * Vk::Chat::MAX_LENGTH
      expect(@chat.__send__(:split_message, "#{long_message}\n321")).to contain_exactly("#{long_message}\n", "321\n")

      length = (Vk::Chat::MAX_LENGTH * 2 / 400) + 2
      long_message = length.downto(0).each_with_object(+'') do |_i, s|
        s << ('i' * 400) << "\n"
      end
      expect(@chat.__send__(:split_message, long_message).size).to eq 3
    end
  end

  describe 'Wall list processing' do
    before :each do
      @chat = FactoryBot.create(:chat)
    end

    it 'should add walls' do
      expect(@chat.walls.size).to eq 0

      wall = FactoryBot.create(:wall, id: 1, domain: 'wall1')
      allow(wall).to receive(:correct?) { true }
      @chat.add(wall)

      expect(@chat.walls.size).to eq 1
    end

    it 'should detect if maximal wall count reached' do
      expect do
        1.upto(Vk::Chat::WATCH_LIMIT + 1) do |x|
          wall = FactoryBot.create(:wall, id: x, domain: "wall#{x}")
          allow(wall).to receive(:correct?) { true }
          @chat.add(wall)
        end
      end.to raise_error(Vk::TooMuchGroups)
    end

    it 'should not add one wall twice' do
      wall = FactoryBot.create(:wall, id: 1, domain: 'wall1')
      allow(wall).to receive(:correct?) { true }
      @chat.add(wall)

      expect { @chat.add(wall) }.to raise_error(Vk::AlreadyWatching)
      expect(@chat.walls.size).to eq 1
    end
  end

  describe 'Post delivery' do
    def tg_ok(result = {})
      { status: 200, body: { ok: true, result: result }.to_json }
    end

    def photo_sent
      tg_ok(photo: [{ file_id: 'abc' }])
    end

    def tg_error(code, description, parameters = nil)
      body = { ok: false, error_code: code, description: description }
      body[:parameters] = parameters if parameters
      { status: code, body: body.to_json }
    end

    def album
      Vk::Album.new(
        'x',
        load_json_fixtures("#{File.dirname(__FILE__)}/../../fixtures/vk_informer_attachment/album/hash.json")
      )
    end

    def deliver(*attachments)
      @chat.send_post(instance_double(Vk::Post, message_id: 1, data: attachments))
    end

    # Latest stub wins in WebMock, so each example can override the defaults
    def stub_api(endpoint, *responses)
      stub_request(:post, %r{/#{endpoint}\z}).to_return(*responses)
    end

    def uploaded?(req)
      req.body.include?('filename=')
    end

    before :each do
      @chat = FactoryBot.create(:chat)
      @download = stub_request(:get, %r{\Ahttp://example\.com/}).to_return(status: 200, body: 'image')
      @message_api = stub_api('sendMessage', tg_ok)
      @group_api = stub_api('sendMediaGroup', tg_ok([]))
      @photo_api = stub_api('sendPhoto', photo_sent)
    end

    it 'should send photo by URL without downloading it' do
      photo = album
      deliver(photo)

      expect(@photo_api).to have_been_made.once
      expect(@message_api).not_to have_been_made
      expect(@download).not_to have_been_made
      expect(photo.to_hash[:media]).to eq 'abc'
    end

    it 'should upload photo if Telegram could not fetch URL' do
      stub_api('sendPhoto', tg_error(400, 'Bad Request: WEBPAGE_CURL_FAILED'), photo_sent)
      photo = album
      deliver(photo)

      expect(@download).to have_been_made.once
      expect(a_request(:post, %r{/sendPhoto\z}).with { |req| uploaded?(req) }).to have_been_made.once
      expect(photo.to_hash[:media]).to eq 'abc'
    end

    it 'should send text link if both URL and upload were rejected' do
      stub_api('sendPhoto', tg_error(400, 'Bad Request: wrong type of the web page content'))
      deliver(album)

      expect(@photo_api).to have_been_made.twice
      expect(a_request(:post, %r{/sendMessage\z}).with(body: %r{vk\.com%2Falbum})).to have_been_made.once
    end

    it 'should skip upload if download fails' do
      stub_request(:get, %r{\Ahttp://example\.com/}).to_return(status: 404)
      stub_api('sendPhoto', tg_error(400, 'Bad Request: failed to get HTTP URL content'))
      deliver(album)

      expect(@photo_api).to have_been_made.once
      expect(@message_api).to have_been_made.once
    end

    it 'should not try other variants for chat errors' do
      stub_api('sendPhoto', tg_error(400, 'Bad Request: chat not found'))
      deliver(album)

      expect(@photo_api).to have_been_made.once
      expect(@download).not_to have_been_made
      expect(@message_api).not_to have_been_made
    end

    it 'should retry the same variant on rate limit' do
      allow(@chat).to receive(:sleep)
      stub_api('sendPhoto', tg_error(429, 'Too Many Requests: retry after 1', retry_after: 1), photo_sent)
      deliver(album)

      expect(@chat).to have_received(:sleep).with(1)
      expect(@photo_api).to have_been_made.twice
      expect(@download).not_to have_been_made
    end

    it 'should disable chat if bot was blocked' do
      stub_api('sendPhoto', tg_error(403, 'Forbidden: bot was blocked by the user'))
      deliver(album)

      expect(@chat.reload.enabled?).to be false
      expect(@download).not_to have_been_made
    end

    it 'should upload media group if Telegram could not fetch URLs' do
      rejected = tg_error(400, 'Bad Request: failed to send message #1 with the error message "WEBPAGE_CURL_FAILED"')
      stub_api('sendMediaGroup', rejected, tg_ok([]))
      deliver(Vk::MediaGroup.new([album, album]))

      expect(@group_api).to have_been_made.twice
      expect(
        a_request(:post, %r{/sendMediaGroup\z}).with do |req|
          req.body.include?('attach://photo0') && req.body.include?('name="photo1"')
        end
      ).to have_been_made.once
    end

    it 'should send photos one by one if media group upload was rejected too' do
      stub_api('sendMediaGroup', tg_error(400, 'Bad Request: IMAGE_PROCESS_FAILED'))
      deliver(Vk::MediaGroup.new([album, album]))

      expect(@group_api).to have_been_made.twice
      expect(@photo_api).to have_been_made.twice
    end
  end
end
