require 'optser'

require 'serf/middleware/error_handler'
require 'serf/middleware/parcel_freezer'
require 'serf/middleware/parcel_masher'
require 'serf/middleware/policy_checker'
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
    #   use Serf::Middleware::ParcelMasher
    #   use Serf::Middleware::UuidTagger
    #   use Serf::Middleware::ParcelFreezer
    #   use Serf::Middleware::ErrorHandler
    #   use Serf::Middleware::PolicyChecker, @policy_chain
    #   use Serf::Serfer
    #
    def use_defaults
      use Serf::Middleware::ParcelMasher
      use Serf::Middleware::UuidTagger
      use Serf::Middleware::ParcelFreezer
      use Serf::Middleware::ErrorHandler
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
