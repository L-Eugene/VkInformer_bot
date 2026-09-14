# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper")

describe Vk::Post do
  def photo_node(index)
    { type: 'photo', photo: { sizes: [{ height: 100, url: "http://example.com/photo#{index}.jpg" }] } }
  end

  before :each do
    @download = stub_request(:get, %r{\Ahttp://example\.com/}).to_return(status: 200, body: 'image')
    @wall = FactoryBot.build(:wall, domain: 'x')
  end

  it 'should group photos into media group without downloading them' do
    post = Vk::Post.new({ id: 1, text: 'hello', attachments: [photo_node(1), photo_node(2)] }, @wall)

    expect(post.data.first).to be_a(Vk::MediaGroup)
    expect(post.data.first.photos.size).to eq 2
    expect(post.data.last).to be_a(Vk::Textual)
    expect(@download).not_to have_been_made
  end

  it 'should keep single photo as is' do
    post = Vk::Post.new({ id: 1, text: 'hello', attachments: [photo_node(1)] }, @wall)

    expect(post.data.first).to be_a(Vk::Photo)
    expect(post.data.first.use_method).to eq :send_photo
  end
end
