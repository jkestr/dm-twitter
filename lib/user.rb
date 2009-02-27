require 'rubygems'
require 'dm-core'

class User
	include DataMapper::Resource

	property :id, Integer, :serial => true
	property :name, String
	property :screen_name, String, :key => true
	property :email, String, :key => true
	property :location, String
	property :description, Text, :lazy => false
	property :profile_image_url, String
	property :url, String
	property :property, Boolean
	property :followers_count, Integer
end
