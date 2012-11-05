require 'serf/util/options_extraction'

module Serf
module Middleware

  class PolicyChecker
    include Serf::Util::OptionsExtraction

    attr_reader :app
    attr_reader :policy_chain

    def initialize(app, *args)
      extract_options! args
      @app = app
      @policy_chain = opts :policy_chain, []
    end

    ##
    # Iterates the policy chain and does a check for each policy.
    # Assumes that policies will raise errors on any policy failure.
    def call(parcel)
      policy_chain.each do |policy|
        policy.check! parcel
      end
      app.call parcel
    end

  end

end
end
