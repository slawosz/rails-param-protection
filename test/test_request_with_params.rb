require 'action_dispatch'

module ActionDispatch
  class TestRequestWithParams < TestRequest
    def params=(params)
      @env["action_dispatch.request.parameters"] = params
    end
  end
end
