class Dice
  def self.roll(dices = 5)
    dices.times.map { rand (1..6) }
  end

  def self.name(combination)
    number_of_dices = combination
      .group_by { |number| number }
      .map { |number, dices| [number, dices.count] }
      .to_h

    values = number_of_dices.values.sort
    dices = combination.sort

    if values === [1, 1, 1, 2]
      'Pair'
    elsif values === [1, 2, 2]
      'Two Pair'
    elsif values === [1, 1, 3]
      'Three-of-a-kind'
    elsif dices === [1,2,3,4,5]
      'Small Straight'
    elsif dices === [2,3,4,5,6]
      'Big Straight'
    elsif values === [2, 3]
      'Full House'
    elsif values === [1, 4]
      'Four-of-a-kind'
    elsif values === [5]
      'Poker'
    else
      '¯\_(ツ)_/¯'
    end
  end

  def self.symbol(dice)
    case dice
    when 1
      '⚀'
    when 2
      '⚁'
    when 3
      '⚂'
    when 4
      '⚃'
    when 5
      '⚄'
    when 6
      '⚅'
    end
  end
end
