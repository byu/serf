require 'serf/errors/policy_failure'

class FailingPolicy

  def check!(parcel)
    raise Serf::Errors::PolicyFailure, 'Failed Policy'
  end

end
