class MainController < ApplicationController
  before_action { flash[:notice] = 'aaa' }
end
