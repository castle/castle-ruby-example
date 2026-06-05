# frozen_string_literal: true

module Users
  # Demonstrates the Lists API: create a list and fetch all lists. These are
  # account-level API-secret operations, so they live behind the default
  # `authenticate_user!` like the rest of the demo.
  class ListsController < ApplicationController
    # Renders the form (and any result from a previous POST).
    def show; end

    # Creates a list and then fetches every list, echoing the Castle responses.
    def create
      @payload = {
        name: params[:name].presence || 'demo-blocklist',
        color: params[:color].presence || '$red',
        primary_field: params[:primary_field].presence || 'user.email'
      }

      created = castle.create_list(@payload)
      all_lists = castle.get_all_lists
      @result = { created: created, all_lists: all_lists }
    rescue Castle::Error => e
      @error = e.message
    ensure
      render :show
    end
  end
end
