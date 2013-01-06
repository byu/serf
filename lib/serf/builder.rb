require 'optser'

require 'serf/middleware/error_handler'
require 'serf/middleware/parcel_freezer'
require 'serf/middleware/parcel_masher'
require 'serf/middleware/policy_checker'
require 'serf/middleware/request_timer'
require 'serf/middleware/uuid_tagger'
require 'serf/serfer'

module Serf

  class Builder
    def initialize(*args, &block)
      opts = Optser.extract_options! args

      @run = opts.get :interactor
      @use = []
      @policy_chain = opts.get :policy_chain, []

      if block_given?
        instance_eval(&block)
      else
        use_defaults
      end
    end

    ##
    # Set a default chain of the following:
    #
    #   use_default_middleware
    #   use_default_serfer_stage
    #
    def use_defaults
      use_default_middleware
      use_default_serfer_stage
    end

    ##
    # Add the following middleware to the chain:
    #
    #   use Serf::Middleware::RequestTimer
    #   use Serf::Middleware::ParcelMasher
    #   use Serf::Middleware::UuidTagger
    #   use Serf::Middleware::ErrorHandler
    #
    def use_default_middleware
      use Serf::Middleware::RequestTimer
      use Serf::Middleware::ParcelMasher
      use Serf::Middleware::UuidTagger
      use Serf::Middleware::ErrorHandler
    end

    ##
    # Add the following middleware to the chain:
    #
    #   use Serf::Middleware::ParcelFreezer
    #   use Serf::Middleware::PolicyChecker, @policy_chain
    #   use Serf::Serfer
    #
    def use_default_serfer_stage
      use Serf::Middleware::ParcelFreezer
      use Serf::Middleware::PolicyChecker, policy_chain: @policy_chain
      use Serf::Serfer
    end

    def use(middleware, *args, &block)
      @use << proc { |app| middleware.new(app, *args, &block) }
    end

    def run(interactor)
      @run = interactor
    end

    def to_app
      @use.reverse.inject(@run) { |a,e| e[a] }
    end

  end

end
