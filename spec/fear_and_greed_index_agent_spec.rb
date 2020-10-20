require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::FearAndGreedIndexAgent do
  before(:each) do
    @valid_options = Agents::FearAndGreedIndexAgent.new.default_options
    @checker = Agents::FearAndGreedIndexAgent.new(:name => "FearAndGreedIndexAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
