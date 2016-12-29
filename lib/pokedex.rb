require 'sinatra'
require 'sinatra/reloader' if development?
require 'httparty'
require 'liquid'
require 'erb'
require 'sass'

require_relative "./functions"


get '/css/:stylesheet.css' do |stylesheet|
  scss :"scss/#{stylesheet}"
end




total_pokemon = 721



get '/' do


  @title = 'Welcome to the Pokedex!'

  erb :index, {
    :layout => :'templates/layout',
  }
end


get '/type/:type' do
  type = params[:type]
  pokemon = HTTParty.get("http://pokeapi.co/api/v2/type/#{type}")
  parsed_type_data = JSON.parse(pokemon.body)

  @type = type

  @pokemon = parsed_type_data['pokemon']


  @title = "#{@type.capitalize} Pokemon!"

  erb :type, {
    :layout => :'templates/layout',
  }
end


get '/color/:color' do
  color = params[:color]
  pokemon = HTTParty.get("http://pokeapi.co/api/v2/pokemon-color/#{color}")
  parsed_color_data = JSON.parse(pokemon.body)

  @color = color

  @pokemon = parsed_color_data['pokemon_species']


  @title = "#{@color.capitalize} Pokemon!"

  erb :color, {
    :layout => :'templates/layout',
  }
end


get '/ability/:ability' do
  ability = params[:ability]
  pokemon = HTTParty.get("http://pokeapi.co/api/v2/ability/#{ability}")
  parsed_ability_data = JSON.parse(pokemon.body)

  @ability = parsed_ability_data['name']
  @ability_descr = parsed_ability_data['effect_entries']

  @pokemon = parsed_ability_data['pokemon']


  @title = "Ability: #{@ability.capitalize}"

  erb :ability, {
    :layout => :'templates/layout',
  }
end


get '/pokemon/:pokemon_id' do
  pokemon_id = params[:pokemon_id]
  # Why doesn't the get_data function work here instead?
  pokemon = HTTParty.get("http://pokeapi.co/api/v2/pokemon/#{pokemon_id}")
  parsed_pokemon_data = JSON.parse(pokemon.body)

  # parsed_pokemon_data = get_data("http://pokeapi.co/api/v2/pokemon/#{pokemon_id}")

  @name = parsed_pokemon_data["name"].split.map(&:capitalize).join(' ')
  @id = parsed_pokemon_data["id"]


  @sprite_url_regular = parsed_pokemon_data["sprites"]["front_default"]
  @sprite_url_shiny = parsed_pokemon_data["sprites"]["front_shiny"]


  @types = parsed_pokemon_data["types"].map { |type_data| type_data["type"]["name"].split.map(&:capitalize).join(' ') }


  stats = parsed_pokemon_data["stats"].map { |type_data| type_data["base_stat"].to_s }
  stat_names = parsed_pokemon_data["stats"].map { |type_data| type_data["stat"]["name"].sub('-', ' ').split(/ |\_/).map(&:capitalize).join(" ") }
  @full_stats = Hash[stat_names.reverse.zip stats.reverse]


  @abilities = parsed_pokemon_data["abilities"];

  @abilities.each_with_index do |item, i|
    name = item["ability"]["name"]
    ability_api = HTTParty.get("http://pokeapi.co/api/v2/ability/#{name}")
    parsed_ability_data = JSON.parse(ability_api.body)

    ability_descr = parsed_ability_data["effect_entries"][0]["short_effect"]

    @abilities[i]["ability"]["name"] = @abilities[i]["ability"]["name"].sub('-', ' ').split(/ |\_/).map(&:capitalize).join(" ")

    @abilities[i]["description"] = ability_descr
    @abilities[i]["id"] = item["ability"]["url"].split("/")[6].to_i
  end


  pokemon_num = parsed_pokemon_data["id"]
  @prev_id = pokemon_num - 1
  @next_id = pokemon_num + 1


  pokemon_species = HTTParty.get("http://pokeapi.co/api/v2/pokemon-species/#{pokemon_id}")
  parsed_pokemon_species_data = JSON.parse(pokemon_species.body)

  @descriptions_english = []
  @descriptions_full = parsed_pokemon_species_data["flavor_text_entries"]


  # Create different overall color schemes for each?
  @color = parsed_pokemon_species_data["color"]["name"]


  @growth_rate = parsed_pokemon_species_data["growth_rate"]["name"]

  # Evolution logic below
  evolution_api = parsed_pokemon_species_data["evolution_chain"]["url"]
  pokemon_evolution = HTTParty.get(evolution_api)
  parsed_pokemon_evolution_data = JSON.parse(pokemon_evolution.body)

  @evolution_start = parsed_pokemon_evolution_data["chain"]["species"]["name"]
  @evolution_chain = parsed_pokemon_evolution_data["chain"]["evolves_to"]


  @title = "##{@id}: #{@name}"

  erb :pokemon, {
    :layout => :'templates/layout',
  }
end


