# frozen_string_literal: true

# The API secret authenticates server-to-server calls to Castle. Grab yours
# from the Castle dashboard (Settings -> API) and expose it as an env var.
Castle.configure do |config|
  config.api_secret = ENV.fetch('CASTLE_API_SECRET', '')

  # When Castle is unreachable or returns a 5xx, allow the request through
  # rather than locking users out. Other options: :deny, :challenge, :throw.
  config.failover_strategy = :allow
end
