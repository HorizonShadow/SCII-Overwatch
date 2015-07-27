require_relative "base.rb"

module Site
	module Routes
		class Submit < Base

			get '/submit/?' do
				render_page :submit
			end

			post '/submit/?' do
				file = params[:replay][:tempfile]
				filename = params[:replay][:filename]
				replay = Tassadar::SC2::Replay.new(file)
				server = replay.details[:data][10].first[6...8]
				replay_player = replay.players.select { |pl| pl.name.gsub('<sp/>', '').gsub(' ', '').downcase == params[:name].gsub(' ', '').downcase || pl.id.to_s == params[:name]}
				if replay_player.length >= 2
					redirect to '/submit?error=identical_names'
				end

				if replay_player.nil? || replay_player.length <= 0 then
					redirect to '/submit?error=player_not_found'
				end

				if params[:evidence].length <= 0
					redirect to '/submit?error=no_evidence'
				end
				replay_player = replay_player.first
				player = Player.first(id: replay_player.id)
				if player.nil?
					player = Player.create(
							id: replay_player.id,
					    race: replay_player.actual_race,
					    name: replay_player.name.gsub('<sp/>', '').gsub(' ', ''),
					    server: server
					)
				end

				game = Game.first(
						player: player,
				    map: replay.game.map,
				    time: replay.game.time
				)
				if game.nil?
					game = Game.create(
							player:player,
					    map: replay.game.map,
					    time: replay.game.time,
					    evidence: params[:evidence],
					    uploaded_at: Time.now,
					    winner: replay.game.winner.name.gsub('<sp/>', ''),
					    players: replay.players
					)
				end


				Voter.create(ip: request.ip, game: game)
				FileUtils.cp(file.path, "./files/#{game.id}.SC2Replay")
				redirect to "/game/#{game.id}"
			end

		end
	end
end