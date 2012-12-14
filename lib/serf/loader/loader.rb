require 'hashie'
require 'optser'

require 'serf/builder'
require 'serf/loader/registry'

module Serf
module Loader

  ##
  # The main loader that takes a serfup configuration file and instance evals
  # all the registered components and serfs, which populates the
  # serfup loader registry; then returns a mapping of serf kind names to
  # the instantiated serfs.
  #
  class Loader

    def initialize(*args)
      opts = Optser.extract_options! args
      @registry = opts.get(:registry) { Serf::Loader::Registry.new }
      @builder_class = opts.get :builder_class, Serf::Builder
    end

    ##
    # Loads up the components defined in a serfup configuration, wires up all
    # the "exposed" serfs and returns them in a frozen map.
    #
    # Example Config:
    #
    #   # Config is a simple hash
    #   config = Hashie::Mash.new
    #   # List out the globbed filenames to load up.
    #   config.globs = [
    #     'example/**/*.serf'
    #   ]
    #   # List out the parcel kinds that we need to have serfs built up
    #   # and exposed in the returned Serf Map.
    #   config.serfs = [
    #     'subsystem/requests/create_widget'
    #   ]
    #
    # @params config the loaded yaml configuration file
    # @returns a frozen Serf Map of request parcel kind to serf.
    #
    def serfup(config, base_path='.')
      # Load in all the components listed
      config[:globs].each do |glob_pattern|
        globs = Dir.glob File.join(base_path, glob_pattern)
        globs.each do |filename|
          File.open filename do |file|
            contents = file.read
            instance_eval(contents)
          end
        end
      end

      # Construct all the "serfs"
      map = Hashie::Mash.new
      config[:serfs].each do |serf|
        map[serf] = @registry[serf]
      end

      # return a frozen registry.
      map.freeze
      return map
    end

    private

    ##
    # Registry attr_reader for serf files to access in the instance eval.
    def registry
      @registry
    end

    ##
    # Registry attr_reader for serf files to define a builder's work.
    def serf(*args, &block)
      @builder_class.new(*args, &block).to_app
    end

  end

end
end
