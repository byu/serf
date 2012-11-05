require 'spec_helper'

shared_examples '#opts with nonexistent option' do
  context 'with missing option' do

    it 'returns default data' do
      subject.opts(:nonexistent_option, 'DEFAULT').should == 'DEFAULT'
    end

    it 'returns nil data on no default' do
      subject.opts(:nonexistent_option).should be_nil
    end

    it 'returns block data' do
      calculator = double('calculator')
      calculator.should_receive(:calculate).and_return('DEFAULT')
      subject.opts(:nonexistent_option) {
        calculator.calculate
      }.should == 'DEFAULT'
    end

  end

end

describe Serf::Util::OptionsExtraction do
  let(:given_options) {
    FactoryGirl.create :random_options
  }
  subject { OptionsExtractionWrapper.new given_options }

  describe '#opts!' do

    it 'returns given data' do
      subject.opts!(:option_a).should == given_options.option_a
    end

    it 'fails for missing option' do
      expect {
        subject.opts! :nonexistent_option
      }.to raise_error
    end

  end

  describe '#opts' do

    it 'returns given data' do
      subject.opts(:option_a).should == given_options.option_a
    end

  end

  it_behaves_like '#opts with nonexistent option'

  context 'with no options given' do
    subject { OptionsExtractionWrapper.new }

    it_behaves_like '#opts with nonexistent option'
  end

end
