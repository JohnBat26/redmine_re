require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ReBbProjectPositionTest < ActiveSupport::TestCase
  ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 
    [:re_bb_project_positions])

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
