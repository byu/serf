require 'optser'

module Serf
module Middleware

  class PolicyChecker
    attr_reader :app
    attr_reader :policy_chain

    def initialize(app, *args)
      opts = Optser.extract_options! args
      @app = app
      @policy_chain = opts.get :policy_chain, []
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
