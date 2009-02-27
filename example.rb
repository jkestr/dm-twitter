require 'lib/adapter'
require 'lib/user'

if __FILE__ == $0

	DataMapper.setup(:default, {:adapter => 'twitter'})

	user = User.first(:screen_name => "KSCollective")

	puts user.screen_name
	puts user.url
	puts user.description

end	

