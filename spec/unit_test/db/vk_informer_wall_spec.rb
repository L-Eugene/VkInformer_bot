# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Vk::Wall do
  describe 'Basic' do
    before :each do
      @wall = FactoryBot.create(:wall, id: 1, domain: '1')
    end

    it 'should provide needed attributes' do
      # Database fields
      expect(@wall).to respond_to(:id, :domain, :last_message_id)

      # Relations
      expect(@wall).to respond_to(:cwlinks, :chats)
    end

    it 'should raise if domain is already taken' do
      # Domain already taken exception
      expect { FactoryBot.create(:wall, id: 3, domain: '1') }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'Simple utils' do
    it 'should define if wall is watched' do
      # watched wall
      wall1 = FactoryBot.create(:wall, id: 1, domain: '1')
      chat1 = FactoryBot.create(:chat, id: 1, enabled: false)
      FactoryBot.create(:cwlink, wall: wall1, chat: chat1)

      # disabled chats should be ignored
      expect(wall1.watched?).to be false
      chat1.update_attribute(:enabled, true)

      # enabled chat should be counted
      expect(wall1.reload.watched?).to be true

      # unwatched wall
      wall2 = FactoryBot.create(:wall, id: 2, domain: '2')

      expect(wall2.watched?).to be false
    end
  end

  describe 'Wall processing' do
    before :each do
      @wall = FactoryBot.create(
        :wall,
        id: 1, domain: 'test', last_message_id: 0
      )
      FactoryBot.create(:token, id: 1, key: 'nope')

      fn = 'vk_informer_wall_spec/wall.get.1.json'
      @stub = stub_request(:post, 'https://api.vk.com/method/wall.get')
              .to_return(
                body: IO.read("#{File.dirname(__FILE__)}/../../fixtures/#{fn}")
              )
    end

    after :each do
      remove_request_stub(@stub)
    end

    it 'should process only new messages' do
      expect(@wall.send(:new_messages).size).to eq 5

      @wall.update_attribute(:last_message_id, 18_023)
      expect(@wall.send(:new_messages).size).to eq 0

      @wall.update_attribute(:last_message_id, 17_985)
      expect(@wall.send(:new_messages).size).to eq 3
    end

    it 'should disable private walls' do
      chat = FactoryBot.create(:chat, id: 1, enabled: false)

      allow(@wall)
        .to receive(:http_load)
        .and_raise(Faraday::Error.new('Access denied: this wall available only for community members'))

      chat.walls << @wall

      expect(chat.reload.walls.size).to eq 1
      expect(@wall.send(:new_messages)).to eq []
      expect(chat.reload.walls.size).to eq 0
    end
  end

  describe 'Generate keyboard buttons' do
    it 'should prepare hash' do
      wall = FactoryBot.create(:wall, id: 1, domain: '1')
      row = wall.keyboard_row

      expect(row).to be_instance_of(Array)
      row.each do |button|
        expect(button).to be_instance_of(Hash)
        expect(button).to have_key(:text)
        expect(button).to have_key(:callback_data)
      end

      cd = nil
      expect { cd = JSON.parse(row.first[:callback_data], symbolize_names: true) }.not_to raise_error
      expect(cd).to be_instance_of(Hash)
      expect(cd[:meth]).to eq 'cmd_nop'
      expect(cd[:args]).to eq []

      cd = nil
      expect { cd = JSON.parse(row.last[:callback_data], symbolize_names: true) }.not_to raise_error
      expect(cd).to be_instance_of(Hash)
      expect(cd[:meth]).to eq 'cmd_delete'
      expect(cd[:args]).to include('1')
      expect(cd[:update]).to be true
    end
  end
end
