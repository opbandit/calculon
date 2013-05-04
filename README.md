# Calculon

Calculon provides aggregate time functions for ActiveRecord.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'calculon'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install calculon
```

## Usage
Calculon allows you to group attributes using aggregate functions (sum, avg, min, max, etc) into time buckets (minute, hour, day, month, year).  These buckets are "calendar" size - for instance, "by hour" means between absolute clock hours rather than a relative "within last 60 minutes, between 60-120 minutes ago, etc."

Let's say you have a Game model with two columns, one for Team A's points and the other for Team B's points.

```ruby
class Game
  attr_accessible :team_a_points, :team_b_points
end
```

And now you want to know the total points for both teams by day:

```ruby
Game.by_day(:team_a_points => :sum, :team_b_points => :sum)
```

This will return an array of Game instances where team_a_points and team_b_points are the sums per hour (the attribute time_bucket will give you the name of each bucket).

Now let's say you want to know the average yesterday where Team A scored more than 0 points:

```ruby
Game.by_day(:team_a_points => :avg, :team_b_points => :avg).on(Date.yesterday).where('team_a_points > 0')
```

Now say you hate typing, and want to get points more easily:

```ruby
class Game
  calculon_view :points, :team_a_points => :sum, :team_b_points => :sum
end
```

Now, you can get point sums more naturally:

```ruby
Game.points_by_day.on(Date.yesterday)
Game.points_by_month.where('team_a_points > 0')
Game.points_by_year
```

Let's say, however, that you want to know points by hour, but you want to get 24 results, regardless of whether or not a team scored (i.e., you want to fill in the "missing" hours):

```ruby
# first, get the buckets out
buckets = Game.points_by_hour.on(Date.yesterday).to_buckets

# then, convert to array with filled values
nogame = OpenStruct.new(:team_a_points => 0, :team_b_points => 0)
buckets.to_a(nogame)
```

This will return an array of length 24, with "nogame" filling in each hour for which there was no game.

### Multiple Grouping Columns
If you want to be able to group by other columns per time period, you can do that as well.

```ruby
# the :group_by option takes either a single additional column or an array of columns
buckets = Game.points_by_hour(:group_by => :bracket_id).on(Date.yesterday).to_buckets

# see all of the unique grouping values
buckets.groupings
#=> { :bracket_id => 1, :bracket_id => 2 }

# get all of the time values for just bracket_id 1.  Since this was by day, there will
# be 24 of them
buckets.values_for(:bracket_id => 1)
#=> [ #<Game ...>, #<Game ...>, ... ]

buckets.values_for(:bracket_id => 2)
#=> [ #<Game ...>, #<Game ...>, ... ]

# now, try one that doesn't exist
buckets.values_for(:bracket_id => 100)
#=> [ nil, nil, ... ]

# now, try one that doesn't exist, but w/ default value
buckets.values_for({:bracket_id => 100}, OpenStruct.new(:points => 0))
#=> [ #<OpenStruct points=0>, #<OpenStruct points=0>, ... ]
```

## Supported Databases
Right now, mysql2 is the only supported DB interface supported.