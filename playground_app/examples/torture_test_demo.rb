# frozen_string_literal: true

module TortureTestDemo
  # Mock Data for Crypto
  # Use deep duplication to avoid shared mutable state between duplicated items
  BASE_COINS = [
    { s: "BTC", n: "Bitcoin", p: 45000, c: 2.5, h: [44,45,46,44,45,47,45] },
    { s: "ETH", n: "Ethereum", p: 3200, c: -1.2, h: [33,32,31,32,32,31,32] },
    { s: "SOL", n: "Solana", p: 110, c: 5.4, h: [100,105,108,110,112,110,110] },
    { s: "ADA", n: "Cardano", p: 0.55, c: 0.1, h: [5,5,6,5,6,5,6] },
    { s: "DOT", n: "Polkadot", p: 7.2, c: -0.5, h: [8,7,7,7,7,8,7] }
  ].freeze
  COINS = (1..20).flat_map { BASE_COINS.map { |coin| coin.deep_dup } }.freeze

  CRYPTO_UI = <<~'RUBY'
    class CryptoDashboard < SwiftUIRails::Component::Base
      state :filter, "all" # all, gainers, losers
      state :selected_coin, nil # For sheet
      state :holdings, {} # symbol => amount
      state :search_query, ""

      def mount
        @holdings = { "BTC" => 0.5, "ETH" => 10 }
      end

      def buy_coin(symbol)
        @holdings[symbol] ||= 0
        @holdings[symbol] += 1
        @selected_coin = nil # Close sheet
      end

      def select_coin(idx)
        # We need to find the coin from the list.
        # For demo simplicity, we rebuild the list or access constant.
        # In real app, this would be a DB lookup.
        index = idx.to_i
        return unless index >= 0 && index < TortureTestDemo::COINS.length

        coin = TortureTestDemo::COINS[index]
        @selected_coin = coin
      end

      def filtered_coins
        TortureTestDemo::COINS.each_with_index.select do |c, i|
          # Nil-safe search matching using to_s for safety
          query = search_query.to_s.downcase
          matches_search = query.empty? || c[:n].to_s.downcase.include?(query) || c[:s].to_s.downcase.include?(query)

          matches_filter = case filter
                           when "gainers" then c[:c] > 0
                           when "losers" then c[:c] < 0
                           else true
                           end
          matches_search && matches_filter
        end
      end

      swift_ui do
        NavigationStack do
          # Custom Header with Search
          vstack(spacing: 0) do
            NavigationTitle("Crypto Trader")
            
            # Search Bar
            div.bg(:gray_100).padding.rounded(:lg).margin(:x, 4).margin(:bottom, 2) do
              hstack {
                Image(system_name: :magnifyingglass).fg(:gray_500)
                TextField("Search coins...", text: :search_query).bg(:transparent)
              }
            end
            
            # Filter Segments
            hstack(spacing: 0).padding(:x, 4).padding(:bottom, 2) do
              ["All", "Gainers", "Losers"].each do |f|
                key = f.downcase
                is_selected = filter == key
                
                Button(f) { @filter = key }
                  .on_server_click("update_binding") # Hack: triggers re-render, we need a generic setter
                  .data(server_action_params_value: ["filter", key].to_json)
                  .padding(:y, 2)
                  .padding(:x, 4)
                  .bg(is_selected ? :gray_900 : :gray_200)
                  .fg(is_selected ? :white : :gray_700)
                  .rounded(:md)
                  .margin(:trailing, 2)
                  .font(:subheadline).font_bold
              end
            end
          end.bg(:white).attr(:style, "position: sticky; top: 0; z-index: 50; box-shadow: 0 2px 4px rgba(0,0,0,0.05)")

          # Main Content
          scroll_view do
            # Portfolio Grid
            Section(header: "Portfolio") do
              LazyVGrid(columns: 2) do
                holdings.each do |sym, amount|
                  coin = TortureTestDemo::COINS.find { |c| c[:s] == sym }
                  next unless coin
                  
                  value = amount * coin[:p]
                  
                  card.padding.bg(:gray_50).rounded(:xl).shadow(:sm) do
                    vstack(alignment: :leading) do
                      hstack(justify: :between) do
                        Text(sym).font(:headline)
                        Image(system_name: :bitcoinsign_circle_fill).fg(:orange)
                      end
                      Spacer(min_length: 10)
                      Text("$#{value}").font(:title3).font_bold
                      Text("#{amount} #{sym}").font(:caption).fg(:gray)
                    end
                  end
                end
              end.padding
            end

            # Market List
            Section(header: "Market") do
              LazyVStack do
                # Header Row
                hstack(spacing: 4).padding(:x, 4).padding(:y, 2).fg(:gray_500).font(:caption) do
                  Text("Asset").w(100)
                  Spacer()
                  Text("7D Trend").w(60)
                  Text("Price").w(80).text_align("right")
                end
                
                divider

                # Rows
                ForEach(filtered_coins, id: :first) do |coin_data|
                  # coin_data is [coin, index] because of each_with_index above
                  coin = coin_data[0]
                  idx = coin_data[1]
                  
                  Button {
                    # Row Content
                    hstack(spacing: 4).bg(:white).padding(:x, 4).padding(:y, 3) do
                      # Icon + Name
                      hstack(spacing: 3).w(100) do
                        Circle { Text(coin[:s][0]).fg(:white).font(:caption).font_bold }
                          .frame(32)
                          .fill(coin[:c] > 0 ? :green : :red)
                        
                        vstack(alignment: :leading, spacing: 0) do
                          Text(coin[:s]).font(:headline)
                          Text(coin[:n]).font(:caption).fg(:gray)
                        end
                      end
                      
                      Spacer()
                      
                      # Mini Chart (Trend)
                      Chart.frame(width: 60, height: 30).bg(:transparent) do
                        coin[:h].each_with_index do |price, i|
                          BarMark(x: i, y: (price / 10.0), color: coin[:c] > 0 ? :green : :red)
                        end
                      end
                      
                      # Price + Change
                      vstack(alignment: :trailing, spacing: 0).w(80) do
                        Text("$#{coin[:p]}").font(:callout).font_bold
                        Badge("#{coin[:c]}%", color: coin[:c] > 0 ? :green : :red)
                      end
                    end
                  }.on_server_click(:select_coin).data(server_action_params_value: [idx].to_json)
                  
                  divider.padding(:leading, 50)
                end
              end
            end
          end
          
          # Buy Sheet
          Sheet(is_presented: !!selected_coin) do
            if selected_coin
              vstack(spacing: 20) do
                Circle { 
                  Text(selected_coin[:s][0]).font(:large_title).fg(:white) 
                }.frame(80).fill(selected_coin[:c] > 0 ? :green : :red)
                
                Text(selected_coin[:n]).font(:title).font_bold
                Text("$#{selected_coin[:p]}").font(:large_title).font_bold
                
                Chart.frame(height: 150) do
                  selected_coin[:h].each_with_index do |p, i|
                    BarMark(x: i, y: p, color: :blue)
                  end
                end
                
                Spacer()
                
                Button("Buy #{selected_coin[:s]}")
                  .w(:full).bg(:black).fg(:white).font(:headline).padding.rounded(:xl)
                  .on_server_click(:buy_coin).data(server_action_params_value: [selected_coin[:s]].to_json)
                  
                Button("Cancel") { @selected_coin = nil }
                  .on_server_click("update_binding").data(server_action_params_value: ["selected_coin", nil].to_json)
                  .fg(:gray)
              end.padding
            end
          end
        end
      end
    end
    
    render CryptoDashboard.new
  RUBY

  KANBAN_UI = <<~'RUBY'
    class KanbanBoard < SwiftUIRails::Component::Base
      state :tasks, {
        "todo" => ["Research AI", "Design System", "Database Schema"],
        "wip" => ["Build DSL", "Refactor Components"],
        "done" => ["Init Project"]
      }
      
      def move_card(card, to_col)
        # Simplified move logic with validation
        return unless @tasks.key?(to_col)

        @tasks.each { |_k, v| v.delete(card) }
        @tasks[to_col] << card
      end

      swift_ui do
        vstack.h("screen").bg(:blue_500) do
          # Header
          hstack(justify: :between).padding.bg(:blue_600).fg(:white) do
            Text("Project Board").font(:title3).font_bold
            hstack {
              Circle { Text("JD") }.frame(32).fill(:blue_400)
              Button("Menu") {}.fg(:white)
            }
          end
          
          # Board Area
          scroll_view(axes: :horizontal).padding do
            hstack(alignment: :top, spacing: 16).h(:full) do
              
              ForEach(["todo", "wip", "done"], id: :self) do |col|
                # Column
                vstack(spacing: 8).w(280).bg(:gray_100).rounded(:xl).padding(3).shadow(:lg) do
                  # Col Header
                  hstack(justify: :between) do
                    Text(col.upcase).font(:caption).font_bold.fg(:gray_600)
                    Badge(tasks[col].count.to_s, color: :gray)
                  end.padding(:bottom, 4)
                  
                  # Cards
                  LazyVStack(spacing: 3) do
                    ForEach(tasks[col], id: :self) do |task|
                      card.bg(:white).padding(3).rounded(:md).shadow(:sm).on_click { } do
                        Text(task).font(:subheadline).font_medium.fg(:gray_800)
                        
                        hstack(justify: :end).margin_top(2) do
                          if col != "done"
                            Button("→")
                              .font(:caption).fg(:gray_400).hover_bg(:gray_100).rounded
                              .on_server_click(:move_card)
                              .data(server_action_params_value: [task, col == "todo" ? "wip" : "done"].to_json)
                          end
                        end
                      end
                    end
                  end
                  
                  Spacer()
                  
                  Button {
                    hstack { Image(system_name: :plus); Text("Add a card") }
                  }.fg(:gray_500).w(:full).padding(:y, 2).hover_bg(:gray_200).rounded
                end
              end
              
              # Add Column Placeholder
              div.w(280).h(50).bg(:white).opacity(30).rounded(:xl).flex.items_center.justify_center do
                Text("+ Add list").fg(:white).font_bold
              end
              
            end
          end
        end
      end
    end
    
    render KanbanBoard.new
  RUBY
end
