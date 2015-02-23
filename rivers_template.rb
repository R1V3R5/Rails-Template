initializer 'generators.rb', <<-RUBY
Rails.application.config.generators do |g|
end
RUBY

@recipes = ["haml", "gemfile", "devise", "personalize"]
@prefs = {}
@gems = []
@diagnostics_prefs = []
diagnostics = {}

# >-------------------------- templates/helpers.erb --------------------------start<
def recipes; @recipes end
def recipe?(name); @recipes.include?(name) end
def prefs; @prefs end
def prefer(key, value); @prefs[key].eql? value end
def gems; @gems end
def diagnostics_recipes; @diagnostics_recipes end
def diagnostics_prefs; @diagnostics_prefs end

# @param [say_custom]
def say_custom(tag, text)
	say "\033[1m\033[36m" + tag.to_s.rjust(10) + "\033[0m" + "  #{text}"
end
def say_loud(tag, text)
	say "\033[1m\033[36m" + tag.to_s.rjust(10) + "  #{text}" + "\033[0m"
end
def say_recipe(name)
	say "\033[1m\033[36m" + "recipe".rjust(10) + "\033[0m" + "  Running #{name} recipe..."
end
# end
# @param [say_wizard] text
def say_wizard(text)
	say_custom(@current_recipe || 'composer', text)
end

def ask_wizard(question)
	ask "\033[1m\033[36m" + (@current_recipe || "prompt").rjust(10) + "\033[1m\033[36m" + "  #{question}\033[0m"
end

def yes_wizard?(question)
	answer = ask_wizard(question + " \033[33m(y/n)\033[0m")
	case answer.downcase
		when "yes", "y"
			true
		when "no", "n"
			false
		else
			yes_wizard?(question)
	end
end

def no_wizard?(question); !yes_wizard?(question) end

def multiple_choice(question, choices)
	say_custom('question', question)
	values = {}
	choices.each_with_index do |choice,i|
		values[(i + 1).to_s] = choice[1]
		say_custom( (i + 1).to_s + ')', choice[0] )
	end
	answer = ask_wizard("Enter your selection:") while !values.keys.include?(answer)
	values[answer]
end

@current_recipe = nil
@configs = {}

@after_blocks = []
def stage_two(&block); @after_blocks << [@current_recipe, block]; end
@stage_three_blocks = []
def stage_three(&block); @stage_three_blocks << [@current_recipe, block]; end
@after_bundler_blocks = []
def after_bundler(&block); @after_blocks << [@current_recipe, block]; end
@after_everything_blocks = []
def after_everything(&block); @after_everything_blocks << [@current_recipe, block]; end
@before_configs = {}
def before_config(&block); @before_configs[@current_recipe] = block; end

def copy_from(source, destination)
	begin
		remove_file destination
		get source, destination
	rescue OpenURI::HTTPError
		say_wizard "Unable to obtain #{source}"
	end
end

def copy_from_repo(filename, opts = {})
	repo = 'https://raw.github.com/R1V3R5/Rails-Template/master/'
	repo = opts[:repo] unless opts[:repo].nil?
	if (!opts[:prefs].nil?) && (!prefs.has_value? opts[:prefs])
		return
	end
	source_filename = filename
	destination_filename = filename
	unless opts[:prefs].nil?
		if filename.include? opts[:prefs]
			destination_filename = filename.gsub(/\-#{opts[:prefs]}/, '')
		end
	end
	if (prefer :templates, 'haml') && (filename.include? 'views')
		remove_file destination_filename
		destination_filename = destination_filename.gsub(/.erb/, '.haml')
	end
	if (prefer :templates, 'slim') && (filename.include? 'views')
		remove_file destination_filename
		destination_filename = destination_filename.gsub(/.erb/, '.slim')
	end
	begin
		remove_file destination_filename
		if (prefer :templates, 'haml') && (filename.include? 'views')
			create_file destination_filename, html_to_haml(repo + source_filename)
		elsif (prefer :templates, 'slim') && (filename.include? 'views')
			create_file destination_filename, html_to_slim(repo + source_filename)
		else
			get repo + source_filename, destination_filename
		end
	rescue OpenURI::HTTPError
		say_wizard "Unable to obtain #{source_filename} from the repo #{repo}"
	end
end

def html_to_haml(source)
	begin
		html = open(source) {|input| input.binmode.read }
		Haml::HTML.new(html, :erb => true, :xhtml => true).render
	rescue RubyParser::SyntaxError
		say_wizard "Ignoring RubyParser::SyntaxError"
		html = open(source) {|input| input.binmode.read }
		say_wizard "applying patch" if html.include? 'card_month'
		say_wizard "applying patch" if html.include? 'card_year'
		html = html.gsub(/, {add_month_numbers: true}, {name: nil, id: "card_month"}/, '')
		html = html.gsub(/, {start_year: Date\.today\.year, end_year: Date\.today\.year\+10}, {name: nil, id: "card_year"}/, '')
		result = Haml::HTML.new(html, :erb => true, :xhtml => true).render
		result = result.gsub(/select_month nil/, "select_month nil, {add_month_numbers: true}, {name: nil, id: \"card_month\"}")
		result = result.gsub(/select_year nil/, "select_year nil, {start_year: Date.today.year, end_year: Date.today.year+10}, {name: nil, id: \"card_year\"}")
	end
end

def html_to_slim(source)
	html = open(source) {|input| input.binmode.read }
	haml = Haml::HTML.new(html, :erb => true, :xhtml => true).render
	Haml2Slim.convert!(haml)
end


# full credit to @mislav in this StackOverflow answer for the #which() method:
# - http://stackoverflow.com/a/5471032
def which(cmd)
	exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
	ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
		exts.each do |ext|
			exe = "#{path}#{File::SEPARATOR}#{cmd}#{ext}"
			return exe if File.executable? exe
		end
	end
	return nil
end

say_wizard("\033[1m\033[36m" + "" + "\033[0m")

say_wizard("\033[1m\033[36m" + ' _____       _ _' + "\033[0m")
say_wizard("\033[1m\033[36m" + "|  __ \\     \(_\) |       /\\" + "\033[0m")
say_wizard("\033[1m\033[36m" + "| |__) |__ _ _| |___   /  \\   _ __  _ __  ___" + "\033[0m")
say_wizard("\033[1m\033[36m" + "|  _  /\/ _` | | / __| / /\\ \\ | \'_ \| \'_ \\/ __|" + "\033[0m")
say_wizard("\033[1m\033[36m" + "| | \\ \\ (_| | | \\__ \\/ ____ \\| |_) | |_) \\__ \\" + "\033[0m")
say_wizard("\033[1m\033[36m" + "|_|  \\_\\__,_|_|_|___/_/    \\_\\ .__/| .__/|___/" + "\033[0m")
say_wizard("\033[1m\033[36m" + "                             \| \|   \| \|" + "\033[0m")
say_wizard("\033[1m\033[36m" + "                             \| \|   \| \|" + "\033[0m")
say_wizard("\033[1m\033[36m" + '' + "\033[0m")
say_wizard("\033[1m\033[36m" + "Rails Composer, open source, supported by subscribers." + "\033[0m")
say_wizard("\033[1m\033[36m" + "Please join RailsApps to support development of Rails Composer." + "\033[0m")
say_wizard("Need help? Ask on Stack Overflow with the tag \'railsapps.\'")
say_wizard("Your new application will contain diagnostics in its README file.")
say_wizard("This is a custom composer built off of Rails Wizard and Rails-App-Composer by...")
say_wizard("Joshua Rivers (R1V3R5).  Please refer to Wizard and Composer documentation as I don't provide support")

# >---------------------------------[ HAML ]----------------------------------<

@current_recipe = "haml"
@before_configs["haml"].call if @before_configs["haml"]
say_recipe 'HAML'


@configs[@current_recipe] = config

gem 'haml'
gem 'haml-rails'
gem 'html2haml'

# >--------------------------------[ gemfile] --------------------------------<

@current_recipe = "gemfile"
@before_configs["gemfile"].call if @before_configs["gemfile"]
say_recipe 'gemfile'

@configs[@current_recipe] = config
# gem 'rails', '4.1.4'
gem 'paperclip'
gem 'angularjs-rails'
gem 'workflow'
gem 'quiet_assets'
gem "nested_form"
gem "cancan"
gem 'faker'
gem 'simple_form'
gem 'letter_opener'
gem 'responders'
gem 'better_errors'
gem 'binding_of_caller'
gem 'meta_request', "~> 0.3.0"
gem 'quiet_assets'
gem 'letter_opener'
gem 'jquery-ui-rails'
gem 'jquery-turbolinks'
gem 'therubyracer',  platforms: :ruby
after_bundler do
	generate 'responders:install'
end
# >---------------------------- recipes/extras.rb ----------------------------start<
# @current_recipe = "extras"
# @before_configs["extras"].call if @before_configs["extras"]
# say_recipe 'extras'

# @configs[@current_recipe] = config
# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/extras.rb

## RVMRC
# rvmrc_detected = false
# if File.exist?('.rvmrc')
# 	rvmrc_file = File.read('.rvmrc')
# 	rvmrc_detected = rvmrc_file.include? app_name
# end
# if File.exist?('.ruby-gemset')
# 	rvmrc_file = File.read('.ruby-gemset')
# 	rvmrc_detected = rvmrc_file.include? app_name
# end
# unless rvmrc_detected || (prefs.has_key? :rvmrc)
# 	prefs[:rvmrc] = yes_wizard? "Use or create a project-specific rvm gemset?"
# end
# if prefs[:rvmrc]
# 	if which("rvm")
# 		say_wizard "recipe creating project-specific rvm gemset and .rvmrc"
# 		# using the rvm Ruby API, see:
# 		# http://blog.thefrontiergroup.com.au/2010/12/a-brief-introduction-to-the-rvm-ruby-api/
# 		# https://rvm.io/integration/passenger
# 		if ENV['MY_RUBY_HOME'] && ENV['MY_RUBY_HOME'].include?('rvm')
# 			begin
# 				gems_path = ENV['MY_RUBY_HOME'].split(/@/)[0].sub(/rubies/,'gems')
# 				ENV['GEM_PATH'] = "#{gems_path}:#{gems_path}@global"
# 				require 'rvm'
# 				RVM.use_from_path! File.dirname(File.dirname(__FILE__))
# 			rescue LoadError
# 				raise "RVM gem is currently unavailable."
# 			end
# 		end
# 		say_wizard "creating RVM gemset '#{app_name}'"
# 		RVM.gemset_create app_name
# 		say_wizard "switching to gemset '#{app_name}'"
# 		# RVM.gemset_use! requires rvm version 1.11.3.5 or newer
# 		rvm_spec =
# 			if Gem::Specification.respond_to?(:find_by_name)
# 				Gem::Specification.find_by_name("rvm")
# 			else
# 				Gem.source_index.find_name("rvm").last
# 			end
# 		unless rvm_spec.version > Gem::Version.create('1.11.3.4')
# 			say_wizard "rvm gem version: #{rvm_spec.version}"
# 			raise "Please update rvm gem to 1.11.3.5 or newer"
# 		end
# 		begin
# 			RVM.gemset_use! app_name
# 		rescue => e
# 			say_wizard "rvm failure: unable to use gemset #{app_name}, reason: #{e}"
# 			raise
# 		end
# 		run "rvm gemset list"
# 		if File.exist?('.ruby-version')
# 			say_wizard ".ruby-version file already exists"
# 		else
# 			create_file '.ruby-version', "#{RUBY_VERSION}\n"
# 		end
# 		if File.exist?('.ruby-gemset')
# 			say_wizard ".ruby-gemset file already exists"
# 		else
# 			create_file '.ruby-gemset', "#{app_name}\n"
# 		end
# 	else
# 		say_wizard "WARNING! RVM does not appear to be available."
# 	end
# 	run 'bundle install'
# end

# >------------------------------ end ----------------------------------------<
# >--------------------------------[ Devise ]---------------------------------<

@current_recipe = "devise"
@before_configs["devise"].call if @before_configs["devise"]
say_recipe 'Devise'


@configs[@current_recipe] = config

gem 'devise'

after_bundler do
	generate 'devise:install'
	devise_text = <<-TEXT
  before_filter :update_sanitized_params, if: :devise_controller?

  def update_sanitized_params
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:first_name, :last_name, :username, :email, :password, :name, :password_confirmation)
    end
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:first_name, :last_name, :username, :email, :password, :name, :password_confirmation, :current_password)
    end
  end
TEXT

	if recipes.include? 'mongo_mapper'
		gem 'mm-devise'
		gsub_file 'config/initializers/devise.rb', 'devise/orm/', 'devise/orm/mongo_mapper_active_model'
		generate 'mongo_mapper:devise User'
	elsif recipes.include? 'mongoid'
		gsub_file 'config/initializers/devise.rb', 'devise/orm/active_record', 'devise/orm/mongoid'
	end


	inject_into_file 'config/environments/development.rb', "  config.action_mailer.default_url_options = { host: 'localhost:3000' }" + "\n", :after => "Rails.application.configure do\n"
	inject_into_file 'app/controllers/application_controller.rb', devise_text, :after => "protect_from_forgery with: :exception\n"

	generate 'devise user'
	generate 'devise:views'
	generate 'migration AddNameToUsers name:string'
	rake "db:create db:migrate"
end




# >-----------------------------[ personalize ]-------------------------------<
@current_recipe = "personalize"
@before_configs["personalize"].call if @before_configs["personalize"]
say_recipe 'personalize'

@configs[@current_recipe] = config

if yes? "Do you want to generate a root controller?"
	name = ask("What should it be called?").underscore
	generate :controller, "#{name} index"
	route "root to: '#{name}\#index'"
	remove_file "public/index.html"

end

if yes? "Setup Basic Bootstrap Theme?"
	repo = "https://raw.github.com/R1V3R5/Rails-Template/master/"
	inject_into_file 'app/assets/javascripts/application.js', "//= require jquery-ui" + "\n", :after => "require jquery_ujs\n"
	inject_into_file 'app/assets/javascripts/application.js', "//= require bootstrap" + "\n", :after => "require jquery-ui\n"
	inject_into_file 'config/application.rb', "config.time_zone = 'Eastern Time (US & Canada)'" + "\n", :after => "class Application < Rails::Application\n"
	inject_into_file 'config/application.rb', "config.assets.paths << '#{Rails}/vendor/assets/fonts'" + "\n", :after => "'Eastern Time (US & Canada)\n"
	inject_into_file 'config/application.rb', "config.assets.paths << '#{Rails}/vendor/assets/images'" + "\n", :after => "assets/fonts\n"
	inject_into_file 'app/assets/stylesheets/application.css', " *= require jquery-ui" + "\n", :after => "require_tree .\n"
	inject_into_file 'app/assets/stylesheets/application.css', " *= require bootstrap" + "\n", :after => "require jquery-ui\n"
	inject_into_file 'app/assets/stylesheets/application.css', " *= require bootstrap-theme" + "\n", :after => "require bootstrap\n"
	copy_from_repo "vendor/assets/javascripts/bootstrap.js"
	copy_from_repo "vendor/assets/stylesheets/bootstrap.css"
	copy_from_repo "vendor/assets/stylesheets/bootstrap-theme.css"
end

if yes? "Add folders for AngularJS?"
	repo = "https://github.com/R1V3R5/Rails-Template/master/"
	inject_into_file 'app/assets/javascripts/application.js', "//= require jquery.turbolinks" + "\n", :after => "require jquery\n"
	inject_into_file 'app/assets/javascripts/application.js', "//= require angular" + "\n", :after => "require bootstrap\n"
	inject_into_file 'app/assets/javascripts/application.js', "//= require angular-route" + "\n", :after => "require angular\n"
	inject_into_file 'app/assets/javascripts/application.js', "//= require angular-animate" + "\n", :after => "require angular-route\n"
	empty_directory "app/assets/templates"
	empty_directory "app/assets/javascripts/controllers"
	empty_directory "app/assets/javascripts/services"
	empty_directory "app/assets/javascripts/directives"
	empty_directory "app/assets/javascripts/filters"
	empty_directory "vendor/assets/fonts"
	empty_directory "vendor/assets/images"
	create_file "app/assets/javascripts/controllers/.keep"
	create_file "app/assets/javascripts/services/.keep"
	create_file "app/assets/javascripts/directives/.keep"
	create_file "app/assets/javascripts/filters/.keep"
	create_file "app/assets/templates/.keep"
	create_file "vendor/assets/fonts/.keep"
	create_file "vendor/assets/images/.keep"
	copy_from_repo "vendor/assets/javascripts/underscore.js"

end



after_everything do
	run "find . -name \*.erb -print | sed 'p;s/.erb$/.haml/' | xargs -n2 html2haml"
	application_meta_text = <<-TEXT
    %meta{:charset => "utf-8"}
    %meta{:content => "IE=edge", "http-equiv" => "X-UA-Compatible"}
    %meta{:content => "width=device-width, initial-scale=1", :name => "viewport"}
    %meta{:content => "", :name => "description"}
    %meta{:content => "", :name => "author"}
TEXT
	application_script_text = <<-TEXT
    <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
    <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
TEXT
	application_body_text = <<-TEXT
{:role => "document"}  
    .navbar.navbar-inverse.navbar-fixed-top{:role => "navigation"}
      .container
        .navbar-header
          = link_to "REPLACE!", root_path, class: "navbar-brand"
        .navbar-collapse.collapse
          = render 'layouts/navbar'
    .container.theme-showcase{:role => "main"}
      - if notice || alert
        %p.notice= notice
        %p.alert= alert
      = yield
TEXT
	navbar_text = <<-TEXT
%ul.nav.navbar-nav
  %li.active
    = link_to "Home", root_path
  %li
    %a{:href => "#about"} About
  %li
    %a{:href => "#contact"} Contact
  %li.dropdown
    %a.dropdown-toggle{"data-toggle" => "dropdown", :href => "#"}
      Dropdown
      %b.caret
    %ul.dropdown-menu
      %li
        %a{:href => "#"} Action
      %li
        %a{:href => "#"} Another action
      %li
        %a{:href => "#"} Something else here
      %li.divider
      %li.dropdown-header Nav header
      %li
        %a{:href => "#"} Separated link
      %li
        %a{:href => "#"} One more separated link
%ul.nav.navbar-nav.navbar-right
  - if current_user
    %li
      = link_to "Logout", destroy_user_session_path, method: :delete
  - else
    %li
      = link_to "Register", new_user_registration_path
    %li
      = link_to "Login", new_user_session_path
TEXT

	inject_into_file 'app/views/layouts/application.html.haml', application_meta_text, :after => "%head\n"
	inject_into_file 'app/views/layouts/application.html.haml', application_script_text, :after => "= csrf_meta_tags\n"
	gsub_file 'app/views/layouts/application.html.haml', /= yield.*/, ''
  inject_into_file 'app/views/layouts/application.html.haml', application_body_text, :after => "%body"
	create_file 'app/views/layouts/_navbar.html.haml', navbar_text


end

# >-----------------------------[ Run Bundler ]-------------------------------<

say_wizard "Running Bundler install. This will take a while."
run 'bundle install'
run 'bundle update'
say_wizard "Running after Bundler callbacks."
@after_blocks.each{|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; b[1].call}

@current_recipe = nil
say_wizard "Running after everything callbacks."
@after_everything_blocks.each{|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; b[1].call}
