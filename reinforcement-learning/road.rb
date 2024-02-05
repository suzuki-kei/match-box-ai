
Start = Data.define(:next)

Goal = Data.define

DeadEnd = Data.define

Branch = Data.define(:left_road, :right_road, :left_match_box, :right_match_box) do

    def initialize(left_road:, right_road:, left_match_box: MatchBox.new(4), right_match_box: MatchBox.new(4))
        super
    end

end

def start?(road)
    road.instance_of?(Start)
end

def goal?(road)
    road.instance_of?(Goal)
end

def dead_end?(road)
    road.instance_of?(DeadEnd)
end

def branch?(road)
    road.instance_of?(Branch)
end

