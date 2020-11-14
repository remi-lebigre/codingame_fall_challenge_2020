STDOUT.sync = true # DO NOT REMOVE

SPELL_TYPE_BLUE = :blue
SPELL_TYPE_GREEN = :green
SPELL_TYPE_ORANGE = :orange
SPELL_TYPE_YELLOW = :yellow
COSTS_TO_SPELL_TYPES = {
  [2, 0, 0, 0] => SPELL_TYPE_BLUE,
  [-1, 1, 0, 0] => SPELL_TYPE_GREEN,
  [0, -1, 1, 0] => SPELL_TYPE_ORANGE,
  [0, 0, -1, 1] => SPELL_TYPE_YELLOW,
}

def find_spell(spells, type)
  spells.find { |s| s[:spell_type] == type } || {}
end

def brew!(recipe)
  puts("BREW #{recipe[:id]}")
end

def cast!(spell)
  puts("CAST #{spell[:id]}")
end

def rest!
  puts("REST")
end

def castable?(spell)
  spell[:castable]
end

def find_castable_spell
  spell_index = @my_ingredients.each_with_index.map do |ingredient, index|
    castable = castable?(find_spell(@castable_spells, @spells[index]))
    can_be_crafted = index.zero? ? true : @my_ingredients[index - 1].positive?
    current_insufficient_amount = @total_cost[index].negative?
    current_empty = ingredient <= 0
    last_needed_index = @total_cost.length - 1 - @total_cost.reverse.index { |c| c.negative? }
    needed = index <= last_needed_index

    STDERR.puts "#{index} - castable, can_be_crafted, (current_insufficient_amount || current_empty), needed"
    STDERR.puts "[#{castable}, #{can_be_crafted}, #{(current_insufficient_amount || current_empty)}, #{needed}]"
    castable && can_be_crafted && (current_insufficient_amount || current_empty) && needed
  end.index(true)
  spell_index ? find_spell(@castable_spells, @spells[spell_index]) : {}
end

loop do
  @my_ingredients = []
  @total_cost = []
  @castable_spells = []
  @blue_spell = nil
  @green_spell = nil
  @orange_spell = nil
  @yellow_spell = nil
  action_count = gets.to_i # the number of spells and recipes in play
  actions = action_count.times.map do |i|
    # action_id: the unique ID of this spell or recipe
    # action_type: in the first league: BREW; later: CAST, OPPONENT_CAST, LEARN, BREW
    # delta_0: tier-0 ingredient change
    # delta_1: tier-1 ingredient change
    # delta_2: tier-2 ingredient change
    # delta_3: tier-3 ingredient change
    # price: the price in rupees if this is a potion
    # tome_index: in the first two leagues: always 0; later: the index in the tome if this is a tome spell, equal to the read-ahead tax; For brews, this is the value of the current urgency bonus
    # tax_count: in the first two leagues: always 0; later: the amount of taxed tier-0 ingredients you gain from learning this spell; For brews, this is how many times you can still gain an urgency bonus
    # castable: in the first league: always 0; later: 1 if this is a castable player spell
    # repeatable: for the first two leagues: always 0; later: 1 if this is a repeatable player spell
    action_id, action_type, delta_0, delta_1, delta_2, delta_3, price, tome_index, tax_count, castable, repeatable = gets.split(" ")
    action_id = action_id.to_i
    delta_0 = delta_0.to_i
    delta_1 = delta_1.to_i
    delta_2 = delta_2.to_i
    delta_3 = delta_3.to_i
    price = price.to_i
    tome_index = tome_index.to_i
    tax_count = tax_count.to_i
    castable = castable.to_i == 1
    repeatable = repeatable.to_i == 1
    cost = [delta_0, delta_1, delta_2, delta_3]
    bonuses = [3, 1]
    {
      price: price + (bonuses[i] || 0),
      id: action_id,
      action_type: action_type,
      spell_type: COSTS_TO_SPELL_TYPES[cost],
      castable: castable,
      cost: cost
    }
  end

  players_ingredients = 2.times.map do
    inv_0, inv_1, inv_2, inv_3, score = gets.split(" ").collect { |x| x.to_i }
    {
      ingredients: [inv_0, inv_1, inv_2, inv_3],
      score: score
    }
  end

  recipes = actions.select { |a| a[:action_type] == 'BREW' }.sort_by { |r| -r[:price] }
  target_recipe = recipes.first
  target_recipe_total_ingredients = target_recipe[:cost].map(&:abs).sum
  spells = actions.select { |a| a[:action_type] == 'CAST' }
  @castable_spells = spells.select { |s| s[:castable] }

  @blue_spell = @castable_spells.find { |s| s[:spell_type] == SPELL_TYPE_BLUE }
  @green_spell = @castable_spells.find { |s| s[:spell_type] == SPELL_TYPE_BLUE }
  @orange_spell = @castable_spells.find { |s| s[:spell_type] == SPELL_TYPE_BLUE }
  @yellow_spell = @castable_spells.find { |s| s[:spell_type] == SPELL_TYPE_BLUE }
  @spells = [@blue_spell, @green_spell, @orange_spell, @yellow_spell]

  my_inventory = players_ingredients[0]
  @my_ingredients = my_inventory[:ingredients]
  my_total_ingredients = @my_ingredients.select { |i| i > 0 }.sum
  @total_cost = @my_ingredients.each_with_index.map do |total_ingredient, index|
    total_ingredient + target_recipe[:cost][index]
  end
  brewable = @total_cost.all? { |c| c >= 0 }

  STDERR.puts "recipes: #{recipes}"
  STDERR.puts "spells: #{spells}"
  STDERR.puts "@castable_spells: #{@castable_spells}"
  STDERR.puts "my_inventory: #{my_inventory}"
  STDERR.puts "my_total_ingredients: #{my_total_ingredients}"
  STDERR.puts "target_recipe_total_ingredients: #{target_recipe_total_ingredients}"

  STDERR.puts "target_recipe: #{target_recipe}"
  STDERR.puts "breawble: #{brewable}"

  STDERR.puts "target_recipe_cost: #{target_recipe[:cost]}"
  STDERR.puts "@my_ingredients: #{@my_ingredients}"
  STDERR.puts "@total_cost: #{@total_cost}"

  brew!(target_recipe) && next if brewable
  cast!(@blue_spell) && next if my_total_ingredients < target_recipe_total_ingredients
  spell = find_castable_spell
  cast!(spell) && next if spell.any?
  rest!
end
