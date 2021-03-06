module PlayerHelper
  def bet(player, amount)
    player = player.game.find_player(player)
    amount = player.cash if amount > player.cash
    player.update(total_bet:
      (Game.find(player.game.id).find_players.detect do |game_player|
        game_player == player
      end.total_bet + amount.to_i))
    new_amount = player.cash - amount.to_i
    player.update(cash: new_amount)
    current_game = Game.find(player.game.id)
    current_game.update(pot: (current_game.pot + amount.to_i))
  end

  def find_player(player)
    player.class == User ? User.find(player.id) : AiPlayer.find(player.id)
  end

  def update_actions(current_player)
    Game.find(game.id).find_players.reject { |player| player == current_player || player.action == 2 }
      .each do |player|
        current_player_index = player.game.find_players.index(current_player)
        if current_player != player.game.find_players.last &&
            player.game.find_players.index(player) > current_player_index
          action_count = (player.action) -2
        else
          action_count = (player.action) -1
        end
        player.update(action: action_count)
      end
  end

  def reset(player)
    player.cards.delete_all
    player.update(total_bet: 0, action: 0)
    player
  end

  def call_amount(player)
    Game.find(player.game.id).highest_bet - Game.find(player.game.id).find_players.detect do |game_player|
      game_player == player
    end.total_bet
  end

  def fold(player)
    Game.find(player.game.id).find_players.detect do |game_player|
      game_player == player
    end.update(action: 2, total_bet: 0)
    Message.create! content: "#{username}: Fold" if player.class == AiPlayer
  end

  def take_pot(player)
    game = Game.find(player.game.id)
    pot = game.pot
    game.find_players.detect { |current_player| current_player == player }
      .update(cash: (player.cash + pot))
    player.update(cash: (player.cash + pot))
  end

  def split_pot(winners)
    winners.each do |winner|
      cash_amount = winner.cash + winner.game.pot.to_i / winners.size
      winner.update(cash: cash_amount)
    end
  end

  def display_hand(cards)
    CardAnalyzer.new.find_hand(cards).class.to_s.underscore.humanize
  end

  def display_cards(winner)
    table_cards = Card.where(id: winner.game.game_cards)
    winner_cards = winner.cards.reject do |card|
      table_cards.any? { |table_card| card.value == table_card.value && card.suit == table_card.suit }
    end
  end
end
