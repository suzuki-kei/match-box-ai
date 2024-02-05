require 'road'

# 分かれ道での選択結果
Step = Data.define(:selected, :rejected)

# Road と MatchBox のマッピング
# NOTE: Hash のキーを間違えやすいので別クラスにしている.
class RoadToMatchBoxMap

    def self.make_map(*roads)
        map = {}

        until roads.empty?
            road = roads.pop
            case
                when start?(road)
                    roads.push(road.next)
                when branch?(road)
                    map[road.left_road.object_id] = road.left_match_box
                    map[road.right_road.object_id] = road.right_match_box
                    roads.push(road.left_road)
                    roads.push(road.right_road)
                else
                    # ignore
            end
        end

        map
    end

    def initialize(start)
        @map = self.class.make_map(start)
    end

    def [](road)
        @map[road.object_id]
    end

end

# マッチ箱
MatchBox = Struct.new(:n)

# Road と MatchBox のマッピング
# NOTE: Hash のキーを間違えやすいので別クラスにしている.
class RoadToMatchBoxMap

    def self.make_map(*roads)
        map = {}

        until roads.empty?
            road = roads.pop
            case
                when start?(road)
                    roads.push(road.next)
                when branch?(road)
                    map[road.left_road.object_id] = road.left_match_box
                    map[road.right_road.object_id] = road.right_match_box
                    roads.push(road.left_road)
                    roads.push(road.right_road)
                else
                    # ignore
            end
        end

        map
    end

    def initialize(start)
        @map = self.class.make_map(start)
    end

    def [](road)
        @map[road.object_id]
    end

end

# マッチ箱 AI
class MatchBoxAi

    def self.max_weight(road)
        case
            when start?(road)
                max_weight(road.next)
            when branch?(road)
                [
                    max_weight(road.left_road),
                    max_weight(road.right_road),
                    road.left_match_box.n + road.right_match_box.n,
                ].max
            else
                0
        end
    end

    def self.move_match(from_match_box, to_match_box, n)
        n = [from_match_box.n, n].min
        from_match_box.n -= n
        to_match_box.n += n
    end

    def initialize(start)
        @start = start
        @max_weight = self.class.max_weight(start)
        @road_to_match_box_map = RoadToMatchBoxMap.new(start)
    end

    def solve
        steps = [Step.new(selected=@start.next, rejected=nil)]

        while branch?(steps[-1].selected)
            road = steps[-1].selected
            dice = rand(@max_weight) + 1

            if dice <= road.right_match_box.n
                steps << Step.new(selected=road.right_road, rejected=road.left_road)
            else
                steps << Step.new(selected=road.left_road, rejected=road.right_road)
            end
        end

        steps
    end

    def trained?(road=@start)
        case
            when start?(road)
                trained?(road.next)
            when branch?(road)
                (road.left_match_box.n == 0 || road.right_match_box.n == 0) &&
                    trained?(road.left_road) &&
                    trained?(road.right_road)
            else
                true
        end
    end

    def train(n)
        puts '==== initial state'
        dump

        n.times do |i|
            puts "==== iteration=#{i + 1}"
            steps = solve
            update(steps)
            dump

            if trained?
                puts 'trained'
                break
            end
        end
    end

    private

    def dump
        puts road_to_string(@start)
    end

    def road_to_string(road, indent=0, weight=-1)
        case
            when start?(road)
                [
                    "#{'    ' * indent}#{road.class.name} (#{weight})",
                    "#{road_to_string(road.next, indent + 1)}",
                ].join("\n")
            when branch?(road)
                [
                    "#{'    ' * indent}#{road.class.name} (#{weight})",
                    "#{road_to_string(road.left_road, indent + 1, road.left_match_box.n)}",
                    "#{road_to_string(road.right_road, indent + 1, road.right_match_box.n)}",
                ].join("\n")
            else
                "#{'    ' * indent}#{road.class.name} (#{weight})"
        end
    end

    def update(steps)
        case
            when goal?(steps[-1].selected)
                (1...steps.size).each do |i|
                    self.class.move_match(
                        from_match_box=@road_to_match_box_map[steps[i].rejected],
                        to_match_box=@road_to_match_box_map[steps[i].selected],
                        i)
                end
            when dead_end?(steps[-1].selected)
                self.class.move_match(
                    from_match_box=@road_to_match_box_map[steps[-1].selected],
                    to_match_box=@road_to_match_box_map[steps[-1].rejected],
                    1)
            else
                raise 'BUG'
        end
    end

end

