require 'spec_helper'

require 'serf/errors/policy_failure'

describe Serf::Errors::PolicyFailure do

  it 'is kind of RuntimeError' do
    subject.kind_of? RuntimeError
  end

end
