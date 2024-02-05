require 'road'
require 'reinforcement_learning'

def main
    ai = MatchBoxAi.new(new_roads)
    ai.train(100)
end

def new_roads
    road = Goal.new
    road = Branch.new(left_road=road, right_road=DeadEnd.new)
    road = Branch.new(left_road=DeadEnd.new, right_road=road)
    road = Branch.new(left_road=road, right_road=DeadEnd.new)
    road = Branch.new(left_road=DeadEnd.new, right_road=road)
    Start.new(road)
end

main if $0 == __FILE__

