require 'rails_helper'

describe Agents::AttributeDifferenceAgent do
  def create_message(value = nil)
    message = Message.new
    message.agent = agents(:jane_status_agent)
    message.payload = {
      rate: value
    }
    message.save!

    message
  end

  before do
    @valid_params = {
      path: 'rate',
      output: 'rate_diff',
      method: 'integer_difference',
      expected_update_period_in_days: '1'
    }

    @checker = Agents::AttributeDifferenceAgent.new(name: 'somename', options: @valid_params)
    @checker.user = users(:jane)
    @checker.save!
  end

  describe 'validation' do
    before do
      expect(@checker).to be_valid
    end

    it 'should validate presence of output' do
      @checker.options[:output] = nil
      expect(@checker).not_to be_valid
    end

    it 'should validate presence of path' do
      @checker.options[:path] = nil
      expect(@checker).not_to be_valid
    end

    it 'should validate presence of method' do
      @checker.options[:method] = nil
      expect(@checker).not_to be_valid
    end

    it 'should validate presence of expected_update_period_in_days' do
      @checker.options[:expected_update_period_in_days] = nil
      expect(@checker).not_to be_valid
    end
  end

  describe '#receive' do
    before :each do
      @message = create_message('5.5')
    end

    it 'creates messages when memory is empty' do
      expect {
        @checker.receive([@message])
      }.to change(Message, :count).by(1)
      expect(Message.last.payload[:rate_diff]).to eq(0)
    end

    it 'creates message with extra attribute for integer_difference' do
      @checker.receive([@message])
      message = create_message('6.5')

      expect {
        @checker.receive([message])
      }.to change(Message, :count).by(1)
      expect(Message.last.payload[:rate_diff]).to eq(1)
    end

    it 'creates message with extra attribute for decimal_difference' do
      @checker.options[:method] = 'decimal_difference'
      @checker.receive([@message])
      message = create_message('6.4')

      expect {
        @checker.receive([message])
      }.to change(Message, :count).by(1)
      expect(Message.last.payload[:rate_diff]).to eq(0.9)
    end

    it 'creates message with extra attribute for percentage_change' do
      @checker.options[:method] = 'percentage_change'
      @checker.receive([@message])
      message = create_message('9')

      expect {
        @checker.receive([message])
      }.to change(Message, :count).by(1)
      expect(Message.last.payload[:rate_diff]).to eq(63.636)
    end

    it 'creates message with extra attribute for percentage_change with the correct rounding' do
      @checker.options[:method] = 'percentage_change'
      @checker.options[:decimal_precision] = 5
      @checker.receive([@message])
      message = create_message('9')

      expect {
        @checker.receive([message])
      }.to change(Message, :count).by(1)
      expect(Message.last.payload[:rate_diff]).to eq(63.63636)
    end
  end
end
