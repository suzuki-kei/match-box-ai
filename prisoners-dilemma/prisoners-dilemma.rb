
ACTION_POSITIVE = Data.define
ACTION_NEGATIVE = Data.define

class Game

    def initialize(strategy1, strategy2)
        @player1 = Player.new(strategy1)
        @player2 = Player.new(strategy2)
    end

    def play!(n)
        n.times.each do
            player1_action, player2_action = next_actions
            @player1.actions << player1_action
            @player2.actions << player2_action

            player1_point, player2_point = next_points(player1_action, player2_action)
            @player1.points << player1_point
            @player2.points << player2_point
        end

        [@player1.total_point, @player2.total_point]
    end

    private

    def next_actions
        [
            @player1.next_action(opposition=@player2),
            @player2.next_action(opposition=@player1),
        ]
    end

    def next_points(action1, action2)
        case [action1, action2]
            when [ACTION_POSITIVE, ACTION_POSITIVE]
                [3, 3]
            when [ACTION_POSITIVE, ACTION_NEGATIVE]
                [0, 5]
            when [ACTION_NEGATIVE, ACTION_POSITIVE]
                [5, 0]
            when [ACTION_NEGATIVE, ACTION_NEGATIVE]
                [1, 1]
            else
                raise 'BUG'
        end
    end

end

class Player

    attr_reader :points, :actions

    def initialize(strategy)
        @strategy = strategy
        @points = []
        @actions = []
    end

    def total_point
        @points.sum
    end

    def next_action(opposition)
        @strategy.next_action(opposition)
    end

end

class StrategyBase

    def name
        self.class.name.gsub(/^Strategy/, '')
    end

    def next_action(opposition)
        raise 'Not implemented.'
    end

    def random_action
        [ACTION_POSITIVE, ACTION_NEGATIVE].sample
    end

end

# ランダム
class StrategyRandom < StrategyBase

    def next_action(opposition)
        random_action
    end

end

# 常に ACTION_POSITIVE
class StrategyAlwaysPositive < StrategyBase

    def next_action(opposition)
        ACTION_POSITIVE
    end

end

# 常に ACTION_NEGATIVE
class StrategyAlwaysNegative < StrategyBase

    def next_action(opposition)
        ACTION_NEGATIVE
    end

end

# オウム返し
class StrategyMirror < StrategyBase

    def next_action(opposition)
        opposition.actions[-1] || ACTION_POSITIVE
    end

end

# 複数の戦略からランダムに選択
class StrategyMixed < StrategyBase

    def initialize(strategies)
        @strategies = strategies.clone
    end

    def next_action(opposition)
        @strategies.sample.next_action(opposition)
    end

end

