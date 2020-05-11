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
    before :each do
      @wall1 = FactoryBot.create(:wall, id: 1, domain: 'club1')
      @wall2 = FactoryBot.create(:wall, id: 2, domain: 'club2z')
      @wall3 = FactoryBot.create(:wall, id: 3, domain: 'noclub15')
      @wall4 = FactoryBot.create(:wall, id: 4, domain: 'noclubatall')
      @wall5 = FactoryBot.create(:wall, id: 5, domain: 'club1554757')
    end

    it 'should define if wall is watched' do
      chat1 = FactoryBot.create(:chat, id: 1, enabled: false)
      FactoryBot.create(:cwlink, wall: @wall1, chat: chat1)

      # disabled chats should be ignored
      expect(@wall1.watched?).to be false
      chat1.update_attribute(:enabled, true)

      # enabled chat should be counted
      expect(@wall1.reload.watched?).to be true

      expect(@wall2.watched?).to be false
    end

    it 'should detect owner_id' do
      expect(@wall1.owner_id).to eq '-1'
      expect(@wall2.owner_id).to eq '0'
      expect(@wall3.owner_id).to eq '0'
      expect(@wall4.owner_id).to eq '0'
      expect(@wall5.owner_id).to eq '-1554757'
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
      expect(@wall.__send__(:new_messages).size).to eq 5

      @wall.update_attribute(:last_message_id, 18_023)
      expect(@wall.__send__(:new_messages).size).to eq 0

      @wall.update_attribute(:last_message_id, 17_985)
      expect(@wall.__send__(:new_messages).size).to eq 3
    end

    it 'should not process unwatched walls' do
      expect_any_instance_of(Vk::Wall).not_to receive(:process)

      Vk::Wall.process
    end

    it 'should disable private walls' do
      chat = FactoryBot.create(:chat, id: 1, enabled: false)

      allow(@wall)
        .to receive(:http_load)
        .and_raise(Faraday::Error.new('Access denied: this wall available only for community members'))

      chat.walls << @wall

      expect(chat.reload.walls.size).to eq 1
      expect(@wall.__send__(:new_messages)).to eq []
      expect(chat.reload.walls.size).to eq 0
    end
  end

  describe 'Generate keyboard buttons' do
    before(:each) do
      @wall = FactoryBot.create(:wall, id: 1, domain: 'domain1')
    end

    it 'should prepare hash for /list command' do
      row = @wall.keyboard_list

      expect(row.length).to eq 1

      expect(row).to be_instance_of(Array)
      row.each do |button|
        expect(button).to be_instance_of(Hash)
        expect(button).to have_key(:text)
      end

      expect(row.first).to have_key(:url)
      expect(row.first[:url]).to eq 'https://vk.com/domain1'
    end

    it 'should prepare hash for /delete command' do
      row = @wall.keyboard_delete

      expect(row.length).to eq 1

      expect(row).to be_instance_of(Array)
      row.each do |button|
        expect(button).to be_instance_of(Hash)
        expect(button).to have_key(:text)
      end

      expect(row.first).to have_key(:callback_data)
      cd = nil
      expect { cd = JSON.parse(row.first[:callback_data], symbolize_names: true) }.not_to raise_error
      expect(cd).to be_instance_of(Hash)

      expect(cd[:action]).to eq 'delete domain1'
      expect(cd[:update]).to be true
    end
  end
end
