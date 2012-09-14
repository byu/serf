require 'hashie'
require 'ice_nine'

require 'serf/error'
require 'serf/errors/not_found'
require 'serf/errors/policy_failure'
require 'serf/util/error_handling'
require 'serf/util/options_extraction'
require 'serf/util/uuidable'

module Serf

  ##
  # Class to drive the command handler execution, error handling, etc
  # of received messages.
  class Serfer
    include Serf::Util::OptionsExtraction
    include Serf::Util::ErrorHandling

    attr_reader :route_set
    attr_reader :uuidable
    attr_reader :not_found_kind
    attr_reader :policy_failure_kind

    def initialize(*args)
      extract_options! args

      @route_set = opts! :route_set
      @uuidable = opts :uuidable, Serf::Util::Uuidable
      @not_found_kind = opts(
        :not_found_kind,
        Serf::Errors::NotFound).to_s.underscore
      @policy_failure_kind = opts(
        :policy_failure_kind,
        Serf::Errors::PolicyFailure).to_s.underscore
    end

    ##
    # Rack-like call to run a set of handlers for a message
    #
    def call(headers, message)
      # Hashie::Mashes are deep copies of the originating hash.
      # Thus we make new deep copies of the messages and headers.
      # We freeze them so policies and commands will be unable to cause
      # side effects in other policies and commands.
      headers = IceNine.deep_freeze Hashie::Mash.new(headers)
      message = IceNine.deep_freeze Hashie::Mash.new(message)

      # Resolve the routes that we want to run
      routes = route_set.resolve headers, message

      # Figure out what we need to return
      results = if routes.size > 0
        # Execute each route, filtering out runs that return nil.
        routes.map { |route|
          run_route route, headers, message
        }.select { |r| r }
      else
        # We return an array of a single parcel_pair
        [[
          uuidable.create_uuids(headers),
          {
            kind: not_found_kind,
            request_kind: message.kind
          }
        ]]
      end

      # return the resulting parcels
      return results
    rescue => e
      e.extend(Serf::Error)
      raise e
    end

    def self.build(*args, &block)
      new *args, &block
    end

    private

    ##
    # Process a route.
    #
    # @return a parcel or nil.
    #
    def run_route(route, headers, message)
      # 1. Check headers+message with the policies (RAISES ON FAILURE)
      _, err = with_error_handling policy_failure_kind do
        route.check_policies! headers, message
      end

      # 2. Execute command if no policy problems
      #   The response_message will be: result, error event or nil.
      response_message, err = with_error_handling do
        route.execute! headers, message
      end unless err

      # Return nil if response is still nil, and no error
      response_message ||= err
      return nil if response_message.nil?

      # 3. Create with the response headers
      #   NOTE: We are guaranteed that headers is a Hashie::Mash.
      response_headers = uuidable.create_uuids headers

      # 4. Return the response headers and message as a parcel pair
      return [response_headers, response_message]
    end

  end

end
