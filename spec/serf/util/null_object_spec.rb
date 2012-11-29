require 'spec_helper'

require 'securerandom'

require 'serf/util/null_object'

describe Serf::Util::NullObject do
  let(:random_method_name) {
    SecureRandom.hex.to_sym
  }

  it 'returns itself on any fuzzy method call' do
    expect(subject.send(random_method_name)).to eq(subject)
  end

  it 'returns itself on a missing method' do
    expect(subject.my_missing_method).to eq(subject)
  end

  it 'returns itself on a missing method with params' do
    expect(subject.my_missing_method(1,2,3,4) {
      nil
    }).to eq(subject)
  end

end
