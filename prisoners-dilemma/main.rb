require 'prisoners-dilemma'

def main
    demonstration1
    demonstration2
end

#
# 全ての戦略を総当たりで対戦させ, 戦略間の優劣を確認する.
#
def demonstration1
    puts '==== demonstration1'

    strategies = all_strategies
    name_width = strategies.map(&:name).map(&:size).max

    strategies.each do |strategy1|
        strategies.each do |strategy2|
            game = Game.new(strategy1, strategy2)
            point1, point2 = game.play!(1000)

            puts sprintf('%-*s vs %-*s ... %4d - %4d point',
                    name_width, strategy1.name,
                    name_width, strategy2.name,
                    point1, point2)
        end
    end
end

#
# 各戦略の優秀さを調べる.
# 対戦相手の戦略は重み付きランダムで選択する.
#
# NOTE:
#     StrategyAlwaysPositive は他の戦略よりも出現率を下げる.
#     StrategyAlwaysPositive は StrategyAlwaysNegative に最高得点を与えるため,
#     StrategyAlwaysPositive の割合が多くなるほど StrategyAlwaysNegative の結果が良くなる.
#
def demonstration2
    puts '==== demonstration2'

    strategies = all_strategies
    name_width = strategies.map(&:name).map(&:size).max

    puts 'probability of occurences'
    total_weight = STRATEGY_TO_WEIGHT_MAP.values.sum
    STRATEGY_TO_WEIGHT_MAP.each do |strategy, weight|
        weight * 100.0 / total_weight
        puts sprintf('    %-*s ... %5.1f%%', name_width, strategy.name, weight * 100.0 / total_weight)
    end

    strategy_point_pairs = strategies.map do |strategy|
        points = 1000.times.map do
            game = Game.new(strategy, new_strategy_randomly)
            point, _ = game.play!(16)
            point
        end

        [strategy, points.sum]
    end

    puts 'total points'
    strategy_point_pairs.sort_by(&:last).reverse.each do |strategy, point|
        puts sprintf('    %-*s ... %4d point', name_width, strategy.name, point)
    end
end

STRATEGY_TO_WEIGHT_MAP = {}.tap do |map|
    map[StrategyRandom.new]            = 100
    map[StrategyAlwaysPositive.new]    = 20
    map[StrategyAlwaysNegative.new]    = 100
    map[StrategyMirror.new]            = 100
    map[StrategyToggleOnWin.new]       = 100
    map[StrategyToggleOnLose.new]      = 100
    map[StrategyToggleOnDraw.new]      = 100
    map[StrategyToggleOnRandom.new]    = 100
    map[StrategyToggleOnLoseTwice.new] = 100
    map[StrategyMixed.new(map.keys)]   = 100
end

def all_strategies
    STRATEGY_TO_WEIGHT_MAP.keys
end

def new_strategy_randomly
    i = rand(STRATEGY_TO_WEIGHT_MAP.values.sum)

    cumulated_weight = 0

    STRATEGY_TO_WEIGHT_MAP.each do |strategy, weight|
        cumulated_weight += weight
        return strategy if i < cumulated_weight
    end

    raise 'BUG'
end

main if $0 == __FILE__

