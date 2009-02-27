require 'cgi'
require 'open-uri'
require 'rubygems'
require 'dm-core'
require 'xmlsimple'

module DataMapper
	module Adapters

		class TwitterAdapter < AbstractAdapter

			# Clients can provide DataMapper with a URI string or hashof options when
			# initializingan adapter. We can store these values and use themfor each
			# request to the Twitter service if the client provides them. Depending on
			# your repository you may wishto verify authentication here rather then
			# waiting for the initial request.
			#
			# name:: Name of the adapter
			# uri_or_options:: A URI string, or Hash of options to initialize this adapter
			#
			def initialize(name, uri_or_options)
				# don't forget to phone home!
				super(name, uri_or_options)

				case uri_or_options
				when Hash
					user = uri_or_options[:user] || ''
					pass = uri_or_options[:pass] || ''	
					@auth = user.blank? || pass.blank? ? nil : [user, path]
				end
			end

			def read_one(query)
				return read(query, query.model, false)
			end

			def read_many(query)
				Collection.new(query) do |set|
					read(query, set, true)
				end
			end

			private

			# Requests a resource from the Twitter API. If the adapter was initialized
			# with the :user and :pass options, they will be used to authenticate the request.
			#
			# method:: Path to follow the base URI 'http://twitter.com'
			# params:: Hash of key/value pairs to be used as the query string
			# returns:: XmlSimple representation of the response from Twitter
			#
			def request(method, params = {})
				uri = "http://twitter.com/#{method}"
				options = {:http_basic_authentication => @auth}

				unless params.blank?
					query = params.map { |k,v| "%s=%s" % [CGI.escape(k), CGI.escape(v)] }
					uri << "?#{query.join('&')}"	
				end

				result = open(uri, options)
				return XmlSimple.xml_in(result.read, {'ForceArray' => false})
			end

			# Map the values from item into an array of the same size and order as Query#fields
			# [id, name, foo, title] => [1, 'Mr. Crackers', nil, 'CATS!']
			#
			def parse_user_values(query, item)
				return query.fields.map { |f| item[f.field.to_s] }
			end

			def generate_users_query(query)
				result = Array.new
				fields = ['user_id', 'email', 'screen_name']

				conditions = query.conditions.select do |condition|
					condition[0] == :eql and fields.include?(condition[1].field.to_s)
				end

				# each condition is a [operator, property, value] tuple.
				for operator, property, value in conditions
					# if an array, each value must be queried in a separate request
					[value].flatten.each { |v| result << [property.field, v] }
				end

				return result
			end

			# Each read has a query and returns a set, #read_one and #read_many should provide
			# the set to load the results into. When called by #read_many nothing needs to be returned
			# as the collection is filling itself, however we must return what ever object #read_one
			# needs to return back to the client code.
			#
			def read(query, set, many = true)
				queries = generate_users_query(query)

				for key, value in queries
					twitter_user = request("users/show.xml", {key => value})
					next if twitter_user.blank? or twitter_user['screen_name'].blank?

					user_values = parse_user_values(query, twitter_user)
					many ? set.load(user_values) : (return set.load(user_values, query))
				end
				
				return
			end

		end

	end
end
