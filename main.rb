
def main
    ai = MatchBoxAi.new(question_count=10, gene_count=10)
    ai.dump

    (1..).each do |n|
        puts "==== #{n} times"
        ai.next!
        ai.dump

        if ai.perfect_gene_exists?
            break
        end
    end
end

class Questions

    POINT_FOR_EACH_QUESTION = 10

    def initialize(n)
        @correct_answers = n.times.map do
            rand(1..3)
        end
    end

    def score(answers)
        correct_count(answers) * POINT_FOR_EACH_QUESTION
    end

    def perfect?(answers)
        answers.zip(@correct_answers).all? do |answer, correct_answer|
            answer == correct_answer
        end
    end

    private

    def correct_count(answers)
        answers.zip(@correct_answers).count do |answer, correct_answer|
            answer == correct_answer
        end
    end

end

class MatchBoxAi

    def self.random_match_boxes(match_box_count)
        match_box_count.times.map do
            MatchBox.new(rand(1..3))
        end
    end

    def self.random_genes(gene_count, match_box_count)
        gene_count.times.map do
            Gene.new(random_match_boxes(match_box_count))
        end
    end

    def initialize(question_count, gene_count)
        @genes = self.class.random_genes(gene_count, question_count)
        @questions = Questions.new(question_count)
    end

    def dump
        scored_genes(@genes).each do |gene, point|
            puts "#{gene} - #{point} point"
        end
    end

    def perfect_gene_exists?
        @genes.any? do |gene|
            @questions.perfect?(gene.answers)
        end
    end

    def next!
        # 点数の降順に並び替える.
        genes = scored_genes(@genes).map(&:first)

        # 上位 2 個体を親として交叉, 突然変異をおこなう.
        gene1, gene2 = genes.take(2)
        gene1, gene2 = crossover(gene1, gene2)
        gene1, gene2 = mutation(gene1), mutation(gene2)

        # 下位 2 個体を新たに生成した個体と入れ替える.
        @genes = genes[...-2] + [gene1, gene2]
    end

    private

    # 点数の降順に整列された [gene, point] の配列.
    def scored_genes(genes)
        gene_point_pairs = genes.map do |gene|
            [gene, @questions.score(gene.answers)]
        end

        gene_point_pairs.sort_by do |gene, point|
            -point
        end
    end

    #
    # 交叉 (crossover)
    #
    # サイコロを 2 つ振り, 出た目の合計を N とする.
    # N-1 箱目と N 箱目の間を交叉する場所とする.
    # ただし, N が 11 以上の場合は交差しない.
    #
    def crossover(gene1, gene2)
        i = rand(1..6) + rand(1..6)
        gene1.crossover(gene2, i)
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

class Gene

    attr_reader :match_boxes

    def initialize(match_boxes)
        @match_boxes = match_boxes
    end

    def to_s
        integer_byte_size = 0.size
        object_id_string = sprintf('0x%0*x', integer_byte_size * 2, object_id)
        match_counts_string = @match_boxes.map(&:match_count).join(' ')
        "Gene(#{object_id_string}, [#{match_counts_string}])"
    end

    def answers
        @match_boxes.map(&:match_count)
    end

    def crossover(target_gene, i)
        gene1 = Gene.new(@match_boxes.take(i) + target_gene.match_boxes.drop(i))
        gene2 = Gene.new(target_gene.match_boxes.take(i) + @match_boxes.drop(i))
        [gene1, gene2]
    end

    def mutation(i)
        mutated_match_boxes = @match_boxes.clone
        mutated_match_boxes[i] = mutate_match_box(@match_boxes[i])
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

