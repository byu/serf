require 'hashie'
require 'ice_nine'

require 'serf/error'
require 'serf/errors/policy_failure'
require 'serf/parcel'
require 'serf/util/error_handling'
require 'serf/util/options_extraction'
require 'serf/util/uuidable'

module Serf

  ##
  # Class to drive the Interactor handler execution, error handling, etc
  # of received messages.
  class Serfer
    include Serf::Util::OptionsExtraction
    include Serf::Util::ErrorHandling

    attr_reader :interactor
    attr_reader :policy_chain

    attr_reader :parcel_builder
    attr_reader :policy_failure_kind
    attr_reader :uuidable

    def initialize(*args)
      extract_options! args

      # How to and when to handle requests
      @interactor = opts! :interactor
      @policy_chain = opts :policy_chain, []

      # Tunable knobs
      @parcel_builder = opts(
        :parcel_builder,
        Serf::Parcel)
      @policy_failure_kind = opts(
        :policy_failure_kind,
        Serf::Errors::PolicyFailure).to_s
      @uuidable = opts :uuidable, Serf::Util::Uuidable
    end

    ##
    # Rack-like call to run a set of handlers for a message
    #
    def call(headers, message)
      # Hashie::Mashes are deep copies of the originating hash.
      # Thus we make new deep copies of the messages and headers.
      headers = IceNine.deep_freeze Hashie::Mash.new(headers)
      message = IceNine.deep_freeze Hashie::Mash.new(message)

      # 1. Check headers+message with the policies (RAISES ON FAILURE)
      _, err = with_error_handling policy_failure_kind do
        check_policies! headers, message
      end

      # 2. Execute interactor if no policy problems
      #   The response_message will be: result, error event or nil.
      response_message, err = with_error_handling do
        interactor.call headers, message
      end unless err

      # 3. Set the response message as an error if step 2 errored.
      response_message ||= err

      # 4. Create with the response headers
      #   NOTE: We are guaranteed that headers is a Hashie::Mash.
      response_headers = uuidable.create_uuids headers

      # 5. Return the response headers and message as a parcel
      return parcel_builder.build response_headers, response_message
    rescue => e
      e.extend(Serf::Error)
      raise e
    end

    def self.build(*args, &block)
      new *args, &block
    end

    private

    ##
    # Just iterates the policy chain and does a check for each policy.
    # Assumes that policies will raise errors on any policy failure.
    def check_policies!(headers, message)
      policy_chain.each do |policy|
        policy.check! headers, message
      end
    end

  end

end
