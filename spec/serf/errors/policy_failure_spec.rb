require 'spec_helper'

require 'serf/errors/policy_failure'

describe Serf::Errors::PolicyFailure do

  it {
    expect(subject).to be_a_kind_of(RuntimeError)
  }

end
