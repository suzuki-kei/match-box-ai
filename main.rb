
def main
    answers = [3, 1, 2, 2, 2, 3, 1, 3, 3, 1]

    ai = MatchBoxAi.new(10, answers)
    ai.dump

    (1..).each do |n|
        puts "==== #{n} times"
        ai.next!
        ai.dump

        if ai.maximum_point == 100
            break
        end
    end
end

class MatchBoxAi

    def self.random_match_boxes(n)
        n.times.map do
            MatchBox.new(rand(1..3))
        end
    end

    def self.random_genes(n)
        n.times.map do
            Gene.new(random_match_boxes(10))
        end
    end

    def initialize(n, answers)
        @genes = self.class.random_genes(n)
        @answers = answers
    end

    def maximum_point
        sorted_genes = ranked_genes(@genes, @answers)
        sorted_genes[0].point(@answers)
    end

    def next!
        # 点数の降順に並び替える.
        sorted_genes = ranked_genes(@genes, @answers)

        # 上位 2 個体を親として交叉, 突然変異をおこなう.
        parent_gene1, parent_gene2 = sorted_genes.take(2)
        gene1, gene2 = crossover(parent_gene1, parent_gene2)
        gene1, gene2 = mutation(gene1), mutation(gene2)

        # 下位 2 個体を新たに生成した個体と入れ替える.
        @genes = sorted_genes[...-2] + [gene1, gene2]
    end

    def dump
        puts "answers = #{@answers.join(' ')}"
        ranked_genes(@genes, @answers).each do |gene|
            puts "#{gene} - #{gene.point(@answers)} point"
        end
    end

    private

    # 点数の降順に並べ替える.
    def ranked_genes(genes, answers)
        genes.sort_by do |gene|
            -gene.point(answers)
        end
    end

    #
    # 交叉 (crossover)
    #
    # サイコロを 2 つ振り, 出た目の合計を N とする.
    # N-1 箱目と N 箱目の間を交叉する場所とする.
    # ただし, N が 11 以上の場合は交差しない.
    #
    def crossover(parent_gene1, parent_gene2)
        i = rand(1..6) + rand(1..6)
        parent_gene1.crossover(parent_gene2, i)
    end

    #
    # 突然変異 (mutation)
    #
    # サイコロを 2 つ振り, 出た目の合計を N とする.
    # N 箱目のマッチ箱に突然変異を起こす.
    # ただし, N=11 の場合は N=1 に置き換え, N=12 の場合は突然変異を起こさない.
    #
    def mutation(gene)
        i = rand(1..6) + rand(1..6)

        case i
            when 2..10
                gene.mutation(i - 1)
            when 11
                gene.mutation(0)
            else
                gene
        end
    end

end

Gene = Data.define(:match_boxes) do

    def to_s
        integer_byte_size = 0.size
        object_id_string = sprintf('0x%0*x', integer_byte_size * 2, object_id)
        match_counts_string = match_boxes.map(&:match_count).join(' ')
        "Gene(#{object_id_string}, [#{match_counts_string}])"
    end

    def point(answers)
        match_boxes.zip(answers).reduce(0) do |point, (match_box, answer)|
            match_box.match_count == answer ? point + 10 : point
        end
    end

    def crossover(target_gene, i)
        gene1 = Gene.new(match_boxes.take(i) + target_gene.match_boxes.drop(i))
        gene2 = Gene.new(target_gene.match_boxes.take(i) + match_boxes.drop(i))
        [gene1, gene2]
    end

    def mutation(i)
        mutated_match_boxes = match_boxes.clone
        mutated_match_boxes[i] = mutate_match_box(match_boxes[i])
        Gene.new(mutated_match_boxes)
    end

    def mutate_match_box(match_box)
        mutation_rules = {1 => 2, 2 => 3, 3 => 1}
        mutated_match_count = mutation_rules[match_box.match_count]
        MatchBox.new(mutated_match_count)
    end

end

MatchBox = Data.define(:match_count)

main if $0 == __FILE__

