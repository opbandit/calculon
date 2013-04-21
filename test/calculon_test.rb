require 'test/unit'
require 'rails'
require 'active_record'
require 'calculon'

ActiveRecord::Base.establish_connection adapter: "mysql2", database: "calculon_test", username: 'root'

class Game < ActiveRecord::Base
  include Calculon
  calculon_view :points, :team_a_points => :sum, :team_b_points => :sum
end

class CalculonTest < Test::Unit::TestCase
  def setup
    Time.zone = "America/New_York"
    old = $stdout
    $stdout = StringIO.new
    ActiveRecord::Base.logger
    ActiveRecord::Schema.define(version: 1) do
      create_table :games do |t|
        t.column :team_a_points, :integer, default: 0
        t.column :team_b_points, :integer, default: 0
        t.timestamps
      end
    end
    $stdout = old
  end

  def teardown
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  def test_results_hash
    Game.create(:team_a_points => 10, :team_b_points => 20, :created_at => 33.hours.ago)
    Game.create(:team_a_points => 30, :team_b_points => 40, :created_at => 2.hours.ago)
    
    assert_equal Game.by_hour(:team_a_points => :sum).length, 2
    results = Game.points_by_hour.to_results_hash
    puts "2 hours ago: #{2.hours.ago.strftime('%Y-%m-%d %H:00:00')}"
    puts "Keys: #{results.keys.sort.inspect}"
    assert_equal [33.hours.ago.strftime("%Y-%m-%d %H:00:00"), 2.hours.ago.strftime("%Y-%m-%d %H:00:00")], results.keys.sort
  end
end
