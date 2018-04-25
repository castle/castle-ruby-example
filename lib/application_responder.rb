# frozen_string_literal: true

# Platformatec responders responder
class ApplicationResponder < ActionController::Responder
  include Responders::FlashResponder
  include Responders::HttpCacheResponder
end
