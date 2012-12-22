require 'spec_helper'

require 'serf/errors/policy_failure'
require 'serf/middleware/policy_checker'

describe Serf::Middleware::PolicyChecker do

  describe '#call' do

    context 'when policy raises error' do

      it 'does not call app' do
        uncalled_mock = double 'uncalled mock'
        app = described_class.new(
          uncalled_mock,
          policy_chain: [
            PassingPolicy.new,
            FailingPolicy.new,
            PassingPolicy.new
          ])
        expect {
          app.call nil
        }.to raise_error(Serf::Errors::PolicyFailure)
      end

    end

    context 'when all policies pass' do

      it 'calls the app' do
        parcel = double 'parcel'
        parcel.should_receive :some_success
        app = described_class.new(
          proc { |parcel|
            parcel.some_success
          },
          policy_chain: [
            PassingPolicy.new,
            PassingPolicy.new
          ])
        app.call parcel
      end

    end

    it 'iterates the policy chain' do
      count = 10
      policy_chain = (1..count).map { |i|
        policy = double 'policy'
        policy.should_receive(:check!).once do |parcel|
          parcel.check_called
        end
        policy
      }

      parcel = double 'parcel'
      parcel.should_receive(:check_called).exactly(count).times
      parcel.should_receive :some_success

      app = described_class.new(
        proc { |parcel|
          parcel.some_success
        },
        policy_chain: policy_chain)
      app.call parcel
    end

  end

end
