# frozen_string_literal: true

module Vendor
  # Serves the Castle browser SDK from the npm install (node_modules).
  class CastleJsController < ActionController::Base
    DIST = Rails.root.join('node_modules/@castleio/castle-js/dist')

    skip_forgery_protection

    def show
      path = resolved_file
      return head :not_found unless path

      send_file path, type: 'application/javascript', disposition: 'inline'
    end

    private

    def resolved_file
      root = DIST.expand_path
      candidate = root.join(params[:filename].to_s).expand_path
      return unless candidate.to_s.start_with?("#{root}#{File::SEPARATOR}")
      return unless candidate.file?

      candidate
    end
  end
end
