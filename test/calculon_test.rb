require 'test/unit'
require 'rails/all'
require 'calculon'

ActiveRecord::Base.establish_connection adapter: "mysql2", database: "calculon_test", username: 'root'
ActiveRecord::Base.default_timezone = :utc
Time.zone = "UTC"

class Game < ActiveRecord::Base
  include Calculon
  calculon_view :points, :team_a_points => :sum, :team_b_points => :sum
end

class CalculonTest < Test::Unit::TestCase
  def setup
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
    results = Game.points_by_hour.to_buckets
    keys = [33.hours.ago.strftime("%Y-%m-%d %H:00:00"), 2.hours.ago.strftime("%Y-%m-%d %H:00:00")]
    assert_equal keys, results.keys.sort
    assert_equal results[keys.first].first.team_a_points, 10 
    assert_equal results[keys.last].first.team_b_points, 40 

    assert_equal Game.by_day(:team_a_points => :sum).length, 2
    results = Game.points_by_day.to_buckets
    keys = [33.hours.ago.strftime("%Y-%m-%d 00:00:00"), 2.hours.ago.strftime("%Y-%m-%d 00:00:00")]
    assert_equal keys, results.keys.sort
    assert_equal results[keys.first].first.team_a_points, 10 
    assert_equal results[keys.last].first.team_b_points, 40     
  end

  def test_results_hash_missing
    Game.create(:team_a_points => 10, :created_at => Time.zone.now - 0.hours)
    Game.create(:team_a_points => 20, :created_at => Time.zone.now - 1.hours)
    Game.create(:team_a_points => 30, :created_at => Time.zone.now - 2.hours)
    Game.create(:team_a_points => 40, :created_at => Time.zone.now - 25.hours)
    
    days = Game.points_by_day.to_a
    assert_equal days.length, 2
    assert_equal days.inject(0) { |s,g| s + g.team_a_points }, 100
  end
end
