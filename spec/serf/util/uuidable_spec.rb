require 'spec_helper'

require 'serf/util/uuidable'

##
# NOTE: Not really great tests here... I really should mock out
#   the uuid_tool to really get at the meat of the work.
#
describe Serf::Util::Uuidable do

  its(:create_coded_uuid) {
    should_not be_nil
    subject.size.should == 22
  }

  describe '#parse_coded_uuid' do

    it 'works' do
      subject.parse_coded_uuid subject.create_coded_uuid
    end

  end

  describe '#create_uuids' do

    it 'works with no parent' do
      uuids = subject.create_uuids
      uuids[:uuid].should_not be_nil
      uuids[:parent_uuid].should be_nil
      uuids[:origin_uuid].should be_nil
    end

    it 'copies origin from parent' do
      uuids = subject.create_uuids origin_uuid: 'MY_UUID'
      uuids[:uuid].should_not be_nil
      uuids[:parent_uuid].should be_nil
      uuids[:origin_uuid].should == 'MY_UUID'
    end

    it 'sets origin from parent[:parent_uuid] if origin is nonexistent ' do
      uuids = subject.create_uuids parent_uuid: 'MY_UUID'
      uuids[:uuid].should_not be_nil
      uuids[:parent_uuid].should be_nil
      uuids[:origin_uuid].should == 'MY_UUID'
    end

    it 'sets origin, parent from parent[:uuid] on missing origin and parent' do
      uuids = subject.create_uuids uuid: 'MY_UUID'
      uuids[:uuid].should_not be_nil
      uuids[:parent_uuid].should == 'MY_UUID'
      uuids[:origin_uuid].should == 'MY_UUID'
    end

  end

end
