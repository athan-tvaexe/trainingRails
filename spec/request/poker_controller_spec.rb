# spec/requests/poker_spec.rb

require 'rails_helper'

RSpec.describe "Poker API", type: :request do
  describe "POST /poker" do
    # Test Case 1: Royal Flush
    context "when the hand is a Royal Flush" do
      let(:cards) { [ "AS", "KS", "QS", "JS", "10S" ] }
      it "returns 'Royal Flush' with rank 10" do
        post '/poker', params: { cards: cards }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["hand"]).to eq("Royal Flush")
        expect(json_response["rank"]).to eq(10)
        expect(json_response["kicker"]).to be_empty
      end
    end

    # Test Case 2: Straight Flush
    context "when the hand is a Straight Flush" do
      let(:cards) { [ "9H", "8H", "7H", "6H", "5H" ] }
      it "returns 'Straight Flush' with rank 9" do
        post '/poker', params: { cards: cards }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["hand"]).to eq("Straight Flush")
        expect(json_response["rank"]).to eq(9)
        expect(json_response["kicker"]).to be_empty
      end
    end

    # Test Case 3: Four of a Kind (Tứ quý)
    context "when the hand is a Four of a Kind" do
      let(:cards) { [ "AS", "AC", "AH", "AD", "KS" ] }
      it "returns 'Four of a Kind' with rank 8 and a kicker" do
        post '/poker', params: { cards: cards }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["hand"]).to eq("Four of a Kind")
        expect(json_response["rank"]).to eq(8)
        expect(json_response["kicker"]).to eq([ "KS" ])
      end
    end

    # Test Case 4: Full House
    context "when the hand is a Full House" do
      let(:cards) { [ "10C", "10D", "10H", "2S", "2H" ] }
      it "returns 'Full House' with rank 7" do
        post '/poker', params: { cards: cards }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["hand"]).to eq("Full House")
        expect(json_response["rank"]).to eq(7)
        expect(json_response["kicker"]).to be_empty
      end
    end

    # Test Case 5: Flush (Đồng chất)
    context "when the hand is a Flush" do
      let(:cards) { [ "KC", "8C", "5C", "3C", "JC" ] }
      it "returns 'Flush' with rank 6" do
        post '/poker', params: { cards: cards }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["hand"]).to eq("Flush")
        expect(json_response["rank"]).to eq(6)
        # Kicker trong Flush là toàn bộ các lá bài
        expect(json_response["kicker"]).to eq([ "KC", "JC", "8C", "5C", "3C" ])
      end
    end

    # Test Case 6: Straight (Sảnh)
    context "when the hand is a Straight" do
      let(:cards) { [ "8C", "7S", "6H", "5D", "4S" ] }
      it "returns 'Straight' with rank 5" do
        post '/poker', params: { cards: cards }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["hand"]).to eq("Straight")
        expect(json_response["rank"]).to eq(5)
        expect(json_response["kicker"]).to be_empty
      end
    end

    # Test Case 7: Three of a Kind (Sám cô)
    context "when the hand is a Three of a Kind" do
      let(:cards) { [ "7C", "7S", "7D", "AH", "2C" ] }
      it "returns 'Three of a Kind' with kickers" do
        post '/poker', params: { cards: cards }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["hand"]).to eq("Three of a Kind")
        expect(json_response["rank"]).to eq(4)
        expect(json_response["kicker"]).to eq([ "AH", "2C" ])
      end
    end

    # Test Case 8: Two Pair (Hai đôi)
    context "when the hand is a Two Pair" do
      let(:cards) { [ "AS", "AC", "KH", "KC", "2D" ] }
      it "returns 'Two Pair' with a single kicker" do
        post '/poker', params: { cards: cards }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["hand"]).to eq("Two Pair")
        expect(json_response["rank"]).to eq(3)
        expect(json_response["kicker"]).to eq([ "2D" ])
      end
    end

    # Test Case 9: One Pair (Một đôi)
    context "when the hand is a One Pair" do
      let(:cards) { [ "AS", "AC", "KH", "QC", "10D" ] }
      it "returns 'One Pair' with three kickers" do
        post '/poker', params: { cards: cards }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["hand"]).to eq("One Pair")
        expect(json_response["rank"]).to eq(2)
        expect(json_response["kicker"]).to eq([ "KH", "QC", "10D" ])
      end
    end

    # Test Case 10: High Card (Mậu thầu)
    context "when the hand is a High Card" do
      let(:cards) { [ "AH", "10D", "7C", "4S", "2H" ] }
      it "returns 'High Card' with kickers" do
        post '/poker', params: { cards: cards }, as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["hand"]).to eq("High Card")
        expect(json_response["rank"]).to eq(1)
        expect(json_response["kicker"]).to eq([ "AH", "10D", "7C", "4S", "2H" ])
      end
    end

    # Test Case 11: Invalid card format
    context "when cards have an invalid format" do
      let(:cards) { [ "AS", "AC", "KH", "QC", "XX" ] }
      it "returns a 400 Bad Request status" do
        post '/poker', params: { cards: cards }, as: :json
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Invalid card format")
      end
    end

    # Test Case 12: Invalid card count
    context "when the card count is not 5" do
      let(:cards) { [ "AS", "AC", "KH", "QC" ] }
      it "returns a 400 Bad Request status" do
        post '/poker', params: { cards: cards }, as: :json
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to include("Invalid card count")
      end
    end
  end
end
