require 'spec_helper'

require 'serf/util/uuidable'

##
# NOTE: Not really great tests here... I need to mock out
#   the uuid_tool to really get at the meat of the work.
#
describe Serf::Util::Uuidable do

  its(:create_coded_uuid) {
    expect(subject).to_not be_nil
    expect(subject.size).to eq(22)
  }

  describe '#parse_coded_uuid' do

    it 'works' do
      subject.parse_coded_uuid subject.create_coded_uuid
    end

  end

  describe '#coded_uuid_time' do
    let(:coded_uuid) {
      'RIEHuF5-EeKLPQQMzuOZ7g'
    }
    let(:rational_time) {
      Rational(1424166190604169, 1048576)
    }

    it 'returns a valid time object' do
      time = subject.coded_uuid_time coded_uuid
      expect(time.to_r).to eq(rational_time)
    end

  end

  describe '#create_uuids' do

    it 'works with no parent' do
      uuids = subject.create_uuids
      expect(uuids[:uuid]).to_not be_nil
      expect(uuids[:parent_uuid]).to be_nil
      expect(uuids[:origin_uuid]).to be_nil
    end

    it 'copies origin from parent' do
      uuids = subject.create_uuids origin_uuid: 'MY_UUID'
      expect(uuids[:uuid]).to_not be_nil
      expect(uuids[:parent_uuid]).to be_nil
      expect(uuids[:origin_uuid]).to eq('MY_UUID')
    end

    it 'sets origin from parent[:parent_uuid] if origin is nonexistent ' do
      uuids = subject.create_uuids parent_uuid: 'MY_UUID'
      expect(uuids[:uuid]).to_not be_nil
      expect(uuids[:parent_uuid]).to be_nil
      expect(uuids[:origin_uuid]).to eq('MY_UUID')
    end

    it 'sets origin, parent from parent[:uuid] on missing origin and parent' do
      uuids = subject.create_uuids uuid: 'MY_UUID'
      expect(uuids[:uuid]).to_not be_nil
      expect(uuids[:parent_uuid]).to eq('MY_UUID')
      expect(uuids[:origin_uuid]).to eq('MY_UUID')
    end

  end

end
