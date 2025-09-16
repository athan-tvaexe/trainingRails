# app/controllers/poker_controller.rb

class PokerController < ApplicationController
  RANKS = {
    "2" => 2, "3" => 3, "4" => 4, "5" => 5, "6" => 6, "7" => 7,
    "8" => 8, "9" => 9, "10" => 10, "J" => 11, "Q" => 12, "K" => 13, "A" => 14
  }.freeze
  SUITS = %w[S H D C].freeze

  def create
    cards_input = params[:cards]

    # 1. Xác thực đầu vào
    unless cards_input.is_a?(Array) && cards_input.size == 5
      return render json: { error: "Invalid card count. Must be 5." }, status: :bad_request
    end

    begin
      @cards = cards_input.map { |card_str| parse_card(card_str) }
    rescue ArgumentError => e
      return render json: { error: e.message }, status: :bad_request
    end

    # 2. Phán đoán và trả về kết quả
    hand, rank, kicker = evaluate_hand(@cards)

    render json: { hand: hand, rank: rank, kicker: kicker }, status: :ok
  end

  private

  # Phân tích chuỗi bài thành hash { rank: ..., suit: ... }
  def parse_card(card_str)
    raise ArgumentError, "Invalid card format: #{card_str}" unless card_str.match?(/^(10|[2-9JQKA])([SHDC])$/)

    rank_str = card_str.length == 3 ? card_str[0..1] : card_str[0]
    suit_str = card_str.length == 3 ? card_str[2] : card_str[1]

    raise ArgumentError, "Invalid card rank: #{rank_str}" unless RANKS.key?(rank_str)
    raise ArgumentError, "Invalid card suit: #{suit_str}" unless SUITS.include?(suit_str)

    { value: RANKS[rank_str], rank: rank_str, suit: suit_str }
  end

  # Thuật toán phán đoán bài (kiểm tra từ cao đến thấp)
  def evaluate_hand(cards)
    # Sắp xếp bài từ cao đến thấp để dễ xử lý
    sorted_cards = cards.sort_by { |card| card[:value] }.reverse

    is_flush = sorted_cards.all? { |c| c[:suit] == sorted_cards.first[:suit] }
    is_straight = check_straight?(sorted_cards)

    counts = sorted_cards.group_by { |c| c[:value] }.transform_values(&:size)

    case
    when is_flush && is_straight && sorted_cards.first[:value] == RANKS["A"]
      [ "Royal Flush", 10, [] ]
    when is_flush && is_straight
      [ "Straight Flush", 9, [] ]
    when counts.value?(4)
      four_card = counts.find { |_, v| v == 4 }.first
      kicker = sorted_cards.find { |c| c[:value] != four_card }
      [ "Four of a Kind", 8, [ kicker[:rank] + kicker[:suit] ] ]
    when counts.value?(3) && counts.value?(2)
      [ "Full House", 7, [] ]
    when is_flush
      [ "Flush", 6, sorted_cards.map { |c| c[:rank] + c[:suit] } ]
    when is_straight
      [ "Straight", 5, [] ]
    when counts.value?(3)
      three_card = counts.find { |_, v| v == 3 }.first
      kickers = sorted_cards.reject { |c| c[:value] == three_card }.map { |c| c[:rank] + c[:suit] }
      [ "Three of a Kind", 4, kickers ]
    when counts.values.count(2) == 2
      pairs = counts.select { |_, v| v == 2 }.keys.sort.reverse
      kicker = sorted_cards.find { |c| c[:value] != pairs[0] && c[:value] != pairs[1] }
      [ "Two Pair", 3, [ kicker[:rank] + kicker[:suit] ] ]
    when counts.value?(2)
      pair_card = counts.find { |_, v| v == 2 }.first
      kickers = sorted_cards.reject { |c| c[:value] == pair_card }.map { |c| c[:rank] + c[:suit] }
      [ "One Pair", 2, kickers ]
    else
      [ "High Card", 1, sorted_cards[0..-1].map { |c| c[:rank] + c[:suit] } ]
    end
  end

  def check_straight?(sorted_cards)
    # Xử lý trường hợp sảnh đặc biệt (A-2-3-4-5)
    if sorted_cards.map { |c| c[:value] } == [ 14, 5, 4, 3, 2 ]
      return true
    end
    # Kiểm tra sảnh thông thường
    (1...sorted_cards.size).all? { |i| sorted_cards[i][:value] == sorted_cards[i-1][:value] - 1 }
  end
end
