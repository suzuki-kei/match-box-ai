
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
            @player1.next_action(opposition_player=@player2),
            @player2.next_action(opposition_player=@player1),
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

    def next_action(opposition_player)
        @strategy.next_action(self, opposition_player)
    end

end

class StrategyBase

    def name
        self.class.name.gsub(/^Strategy/, '')
    end

    def next_action(own_player, opposition_player)
        raise 'Not implemented.'
    end

    def random_action
        [ACTION_POSITIVE, ACTION_NEGATIVE].sample
    end

end

# ランダム
class StrategyRandom < StrategyBase

    def next_action(own_player, opposition_player)
        random_action
    end

end

# 常に ACTION_POSITIVE
class StrategyAlwaysPositive < StrategyBase

    def next_action(own_player, opposition_player)
        ACTION_POSITIVE
    end

end

# 常に ACTION_NEGATIVE
class StrategyAlwaysNegative < StrategyBase

    def next_action(own_player, opposition_player)
        ACTION_NEGATIVE
    end

end

# オウム返し
class StrategyMirror < StrategyBase

    def next_action(own_player, opposition_player)
        opposition_player.actions[-1] || ACTION_POSITIVE
    end

end

# 勝ったら戦略を変更する
class StrategyToggleOnWin < StrategyBase

    def next_action(own_player, opposition_player)
        case
            when own_player.actions.empty?
                ACTION_POSITIVE
            when own_player.points[-1] > opposition_player.points[-1]
                own_player.actions[-1] == ACTION_POSITIVE ? ACTION_NEGATIVE : ACTION_POSITIVE
            else
                own_player.actions[-1]
        end
    end

end

# 負けたら戦略を変更する
class StrategyToggleOnLose < StrategyBase

    def next_action(own_player, opposition_player)
        case
            when own_player.actions.empty?
                ACTION_POSITIVE
            when own_player.points[-1] < opposition_player.points[-1]
                own_player.actions[-1] == ACTION_POSITIVE ? ACTION_NEGATIVE : ACTION_POSITIVE
            else
                own_player.actions[-1]
        end
    end

end

# 引き分けたら戦略を変更する
class StrategyToggleOnDraw < StrategyBase

    def next_action(own_player, opposition_player)
        case
            when own_player.actions.empty?
                ACTION_POSITIVE
            when own_player.points[-1] == opposition_player.points[-1]
                own_player.actions[-1] == ACTION_POSITIVE ? ACTION_NEGATIVE : ACTION_POSITIVE
            else
                own_player.actions[-1]
        end
    end

end

# 一定の確率で戦略を変更する
class StrategyToggleOnRandom < StrategyBase

    def next_action(own_player, opposition_player)
        case
            when own_player.actions.empty?
                ACTION_POSITIVE
            when rand < 0.1
                own_player.actions[-1] == ACTION_POSITIVE ? ACTION_NEGATIVE : ACTION_POSITIVE
            else
                own_player.actions[-1]
        end
    end

end

# 2 連敗したら戦略を変更する
class StrategyToggleOnLoseTwice < StrategyBase

    def next_action(own_player, opposition_player)
        case
            when own_player.actions.size < 2
                ACTION_POSITIVE
            when own_player.points[-1] < opposition_player.points[-1] && own_player.points[-2] < opposition_player.points[-2]
                own_player.actions[-1] == ACTION_POSITIVE ? ACTION_NEGATIVE : ACTION_POSITIVE
            else
                own_player.actions[-1]
        end
    end

end

# 複数の戦略からランダムに選択
class StrategyMixed < StrategyBase

    def initialize(strategies)
        @strategies = strategies.clone
    end

    def next_action(own_player, opposition_player)
        @strategies.sample.next_action(own_player, opposition_player)
    end

end

