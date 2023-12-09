
def main
    ai = new_match_box_ai
    ai.dump

    until ai.perfect_gene_exists?
        ai.next!
        ai.dump
    end
end

def new_match_box_ai
    examination = Examination.new(
            number_of_questions=10,
            number_of_options=3,
            score_for_each_question=10)
    MatchBoxAi.new(examination, number_of_genes=10)
end

class Examination

    # 設問の数.
    attr_reader :number_of_questions

    # 各設問における選択肢の数.
    # どの設問も選択肢の数は同じとなる.
    attr_reader :number_of_options

    # 各設問の配点.
    # どの設問も配点は同じとなる.
    attr_reader :score_for_each_question

    def self.random_answers(number_of_answers, number_of_options)
        number_of_answers.times.map do
            rand(1..number_of_options)
        end
    end

    def initialize(number_of_questions, number_of_options, score_for_each_question)
        @number_of_questions = number_of_questions
        @number_of_options = number_of_options
        @score_for_each_question = score_for_each_question
        @correct_answers = self.class.random_answers(number_of_questions, number_of_options)
    end

    def options
        (1 .. @number_of_options).to_a
    end

    def score(answers)
        correct_count(answers) * @score_for_each_question
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

    def self.random_match_boxes(examination)
        # 設問数の数だけマッチ箱が必要.
        number_of_match_boxes = examination.number_of_questions

        number_of_match_boxes.times.map do
            MatchBox.new(rand(1..examination.number_of_options))
        end
    end

    def self.random_genes(number_of_genes, examination)
        number_of_genes.times.map do
            Gene.new(random_match_boxes(examination))
        end
    end

    def initialize(examination, number_of_genes)
        @examination = examination
        @genes = self.class.random_genes(number_of_genes, examination)
        @generation = 1
    end

    def dump
        puts "==== generation=#{@generation}"

        scored_genes(@genes).each do |gene, point|
            puts "#{gene} - #{point} point"
        end
    end

    def perfect_gene_exists?
        @genes.any? do |gene|
            @examination.perfect?(gene.answers)
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

        @generation += 1
    end

    private

    # 点数の降順に整列された [gene, point] の配列.
    def scored_genes(genes)
        gene_point_pairs = genes.map do |gene|
            [gene, @examination.score(gene.answers)]
        end

        gene_point_pairs.sort_by do |gene, point|
            -point
        end
    end

    #
    # 交叉 (crossover)
    #
    # 書籍では設問数を 10 個固定とし, 以下のルールで交叉をおこなっている.
    #  * サイコロを 2 つ振り, 出た目の合計を N とする.
    #  * N-1 箱目と N 箱目の間を交叉する場所とする.
    #  * ただし, N が 11 以上の場合は交差しない.
    #
    # 設問数や選択肢の数を変更できるように実装したので, 次のルールで交叉をおこなう.
    #  * 設問数を m とする.
    #  * (m * 1.2) の小数点以下を切り捨てた値を n とする.
    #  * [1, n] の範囲で乱数を生成し, その値を i とする.
    #  * i-1 箱目と i 箱目の間を交叉する場所とする.
    #  * ただし, i が M より大きい場合は交差しない.
    #
    def crossover(gene1, gene2)
        m = @examination.number_of_questions
        n = (m * 1.2).to_i
        i = rand(1..n)

        if i <= m
            gene1.crossover(gene2, i)
        else
            [gene1, gene2]
        end
    end

    #
    # 突然変異 (mutation)
    #
    # 書籍では設問数を 10 個固定とし, 以下のルールで突然変異をおこなっている.
    #  * サイコロを 2 つ振り, 出た目の合計を N とする.
    #  * N 箱目のマッチ箱に突然変異を起こす.
    #  * ただし, N=11 の場合は N=1 に置き換え, N=12 の場合は突然変異を起こさない.
    #
    # 設問数や選択肢の数を変更できるように実装したので, 次のルールで突然変異をおこなう.
    #  * 設問数を m とする.
    #  * (m * 1.1) の小数点以下を切り捨てた値を n とする.
    #  * [1, n] の範囲で乱数を生成し, その値を i とする.
    #  * i 箱目のマッチ箱に突然変異を起こす.
    #  * ただし, i が m より大きい場合は突然変異を起こさない.
    #
    def mutation(gene)
        m = @examination.number_of_questions
        n = (m * 1.1).to_i
        i = rand(1..n)

        if i <= m
            gene.mutation(i - 1, mutation_map)
        else
            gene
        end
    end

    def mutation_map
        options = @examination.options
        Hash[options.zip(options.rotate)]
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

    def mutation(i, mutation_map)
        mutated_match_boxes = @match_boxes.clone
        mutated_match_boxes[i] = mutate_match_box(@match_boxes[i], mutation_map)
        Gene.new(mutated_match_boxes)
    end

    private

    def mutate_match_box(match_box, mutation_map)
        mutated_match_count = mutation_map[match_box.match_count]
        MatchBox.new(mutated_match_count)
    end

end

MatchBox = Data.define(:match_count)

main if $0 == __FILE__

