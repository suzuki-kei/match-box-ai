
def main
    new_match_box_ai.train
end

def new_match_box_ai
    items = [
        Item.new(id=1, price=310), # お菓子 1
        Item.new(id=2, price=220), # お菓子 2
        Item.new(id=3, price=70),  # お菓子 3
    ]

    match_boxes = [
        MatchBox.new(id=1, threshold=1), # マッチ箱 B
        MatchBox.new(id=2, threshold=3), # マッチ箱 C
        MatchBox.new(id=3, threshold=8), # マッチ箱 D
        MatchBox.new(id=4, threshold=6), # マッチ箱 A
    ]

    # どの商品を購入すると, どのマッチ箱が発火するか.
    item_id_to_match_box_map = {
        items[0].id => match_boxes[0],
        items[1].id => match_boxes[1],
        items[2].id => match_boxes[2],
    }

    # どのマッチ箱が発火すると, どのマッチ箱に信号を送るか.
    match_box_id_to_match_box_map = {
        match_boxes[0].id => match_boxes[3],
        match_boxes[1].id => match_boxes[3],
        match_boxes[2].id => match_boxes[3],
    }

    MatchBoxAi.new(
        items,
        match_boxes,
        item_id_to_match_box_map,
        match_box_id_to_match_box_map)
end

# 商品
Item = Data.define(:id, :price)

# マッチ箱
MatchBox = Struct.new(:id, :threshold, :accumulated) do

    def initialize(id, threshold)
        super(id, threshold, accumulated=0)
    end

    def activate!
        self.accumulated = self.threshold
    end

    def deactivate!
        self.accumulated = 0
    end

    def activated?
        accumulated >= threshold
    end

end

# マッチ箱 AI
class MatchBoxAi

    def initialize(items, match_boxes, item_id_to_match_box_map, match_box_id_to_match_box_map)
        @items = items
        @match_boxes = match_boxes
        @terminal_match_box = self.class.find_terminal_match_box(match_boxes, match_box_id_to_match_box_map)
        @item_id_to_match_box_map = item_id_to_match_box_map
        @match_box_id_to_match_box_map = match_box_id_to_match_box_map
    end

    def judge(purchase_items)
        deactivate!
        activate!(purchase_items)
        @terminal_match_box.activated?
    end

    def train(max_iterations=10)
        puts '==== initial state'
        dump

        max_iterations.times do |i|
            if trained_perfectly?
                puts 'trained perfectly.'
                break
            end

            puts "==== iteration=#{i + 1}"
            all_combinations_of_purchase_items.each do |purchase_items|
                deactivate!
                activate!(purchase_items)
                update_thresholds!(purchase_items)
            end
            dump
        end
    end

    private

    def self.find_terminal_match_box(match_boxes, match_box_id_to_match_box_map)
        terminal_match_boxes = match_boxes.reject do |match_box|
            match_box_id_to_match_box_map.key?(match_box.id)
        end
        if terminal_match_boxes.size != 1
            raise 'terminal match box is not identified.'
        end
        terminal_match_boxes[0]
    end

    def dump
        thresholds = @match_boxes.map(&:threshold).join(', ')
        puts "thresholds=[#{thresholds}]"

        all_combinations_of_purchase_items.each do |purchase_items|
            deactivate!
            activate!(purchase_items)
            total_price = purchase_items.map(&:price).sum
            puts "    total_price=#{total_price}, activated=#{@terminal_match_box.activated?}"
        end
    end

    # 全ての入力に対して正答するように学習済みであれば true.
    def trained_perfectly?
        all_combinations_of_purchase_items.all? do |purchase_items|
            deactivate!
            activate!(purchase_items)
            total_price = purchase_items.sum(&:price)
            total_price > 500 == @terminal_match_box.activated?
        end
    end

    def deactivate!
        @match_boxes.each(&:deactivate!)
    end

    def activate!(purchase_items)
        match_boxes = @item_id_to_match_box_map.values_at(*purchase_items.map(&:id))
        match_boxes.each(&:activate!)

        until match_boxes.empty?
            match_boxes = match_boxes.reduce([]) do |match_boxes, match_box|
                if next_match_box = @match_box_id_to_match_box_map[match_box.id]
                    next_match_box.accumulated += match_box.threshold
                    match_boxes << next_match_box
                end
                match_boxes
            end
        end
    end

    def update_thresholds!(purchase_items)
        # 間違いタイプ 1
        #     正しい買い方だったのに NG と判断してしまった場合.
        #     -> マッチ箱 B-D のマッチ棒を 1 本減らし, マッチ箱 A のマッチ棒を 1 本増やす.
        #
        # 間違いタイプ 2
        #     間違った買い方だったのに OK と判断してしまった場合.
        #     -> マッチ箱 B-D のマッチ棒を 1 本増やし, マッチ箱 A のマッチ棒を 1 本減らす.
        #
        # 特別ルール
        #    マッチ箱 B-D が興奮していなかった場合, マッチ箱 A が間違ってもペナルティは免除する.
        #    -> 間違いタイプ 1, 2 の処理に条件を追加

        total_price = purchase_items.map(&:price).sum

        # 間違いタイプ 1, 特別ルール
        if total_price <= 500 && @terminal_match_box.activated?
            @match_boxes[0].threshold -= 1 if @match_boxes[0].activated?
            @match_boxes[1].threshold -= 1 if @match_boxes[1].activated?
            @match_boxes[2].threshold -= 1 if @match_boxes[2].activated?
            @match_boxes[3].threshold += 1
        end

        # 間違いタイプ 2, 特別ルール
        if total_price > 500 && !@terminal_match_box.activated?
            @match_boxes[0].threshold += 1 if @match_boxes[0].activated?
            @match_boxes[1].threshold += 1 if @match_boxes[1].activated?
            @match_boxes[2].threshold += 1 if @match_boxes[2].activated?
            @match_boxes[3].threshold -= 1
        end
    end

    # 購入する商品の全パターンを含む配列
    def all_combinations_of_purchase_items
        arrays = [[true, false]] * @items.size
        purchase_flags_array = arrays[0].product(*arrays[1..])

        purchase_flags_array.map do |purchase_flags|
            @items.select.with_index do |item, index|
                purchase_flags[index]
            end
        end
    end

end

main if $0 == __FILE__

