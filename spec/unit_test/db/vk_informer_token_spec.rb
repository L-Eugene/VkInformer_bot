# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Vk::Token do
  before :each do
    @token = FactoryBot.create(:token, id: 1)
  end

  it 'should provide needed attributes' do
    expect(@token).to respond_to(:id, :key)
  end

  it 'should create stat for today if not exists' do
    expect(@token.today).to eq 0

    expect(Vk::Stat.all.size).to eq 1
  end

  it 'should select less used token' do
    t2 = FactoryBot.create(:token, id: 2)
    FactoryBot.create(:stat, token: @token, count: 5, date: Date.today)
    FactoryBot.create(:stat, token: t2, count: 1, date: Date.today)

    expect(Vk::Token.best.id).to eq 2
  end
end
