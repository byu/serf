require 'serf/util/options_extraction'

module Serf
module Routing

  class Route
    include Serf::Util::OptionsExtraction

    attr_reader :policies
    attr_reader :command

    def initialize(*args, &block)
      extract_options! args
      @policies = opts :policies, []
      @command = opts! :command
    end

    def check_policies!(request, context)
      for policy in policies do
        policy.check! request, context
      end
    end

    def execute!(*args, &block)
      command.call *args, &block
    end

    def self.build(*args, &block)
      new *args, &block
    end

  end

end
end
