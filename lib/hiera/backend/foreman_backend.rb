# Foreman Backend for Hiera
class Hiera
  module Backend
    class Foreman_backend
      def lookup(key, scope, order_override, resolution_type)
        fqdn    = scope['fqdn']
        Hiera.debug("Performing Foreman ENC lookup on #{fqdn} for '#{key}'")
        results = nil
	cache_file = "/var/lib/puppet/yaml/foreman/#{fqdn}.yaml"
	if (File.file?(cache_file) and (File.stat(cache_file).mtime > (Time.now - 60)) ) then
	  Hiera.debug('Using cached Foreman Yaml')
          foreman = YAML.load_file(cache_file)
	else
	  Hiera.debug('Downloading Yaml from Foreman')
          foreman = YAML.load(`/etc/puppet/external_node_v2.rb #{fqdn}`)
	end
        Hiera.debug("Imported Foreman yaml:\n#{YAML.dump(foreman)}")
	unless foreman.nil? or not defined?(foreman)
          begin
          case key
            when "environment"
	      Hiera.debug('Returning \'environment\' from Foreman')
              if foreman['environment'] then
              	results = foreman['environment']
              	Hiera.debug("Found environment '#{results}' in Foreman")
              else
              	Hiera.debug("Didn't find environment in Foreman")
              end
            when "classes"
	      Hiera.debug('Returning \'classes\' from Foreman')
              if foreman['classes'] then
                results = foreman['classes'].keys
                Hiera.debug("Adding the following classes from Foreman: #{results}")
              else
                Hiera.debug("No classes added in Foreman")
              end
            when /^parameters.*/
	      Hiera.debug('Looking in Foreman YAML at section \'parameters\'')
              if foreman['parameters'] and foreman['parameters'].has_key?(key.split('::').last) then
                Hiera.debug("Found key in Foreman parameters")
                results = foreman['parameters'][key.split('::').last]
              else
                Hiera.debug("Foreman doesn't have such key in parameters")
              end
            else
	      Hiera.debug('Looking in Foreman YAML at section \'classes\'')
              if foreman['classes'] then
              	key_array = key.split("::")
              	key_class = key_array[0..-2].join("::")
              	key_var = key_array.last
              	if foreman['classes'].has_key?(key_class) then
                  key_vars = foreman['classes'][key_class]
                  if key_vars.has_key?(key_var) then
                    Hiera.debug("Found key in Foreman classes")
                    results = key_vars[key_var]
                  else
                    Hiera.debug("Found '#{key_vars}' in Foreman but not '#{key_var}'")
                  end
		elsif foreman['parameters'].has_key?(key_var) then
		    Hiera.debug("Found '#{key_var}' in Foreman global parameters")
		    results = foreman['parameters'][key_var]
                else
                  Hiera.debug("Key '#{key_class}' not found in Foreman class parameters")
                end
              else
                Hiera.debug("Key not found in Foreman")
                results = nil
              end
            end
          end
        end
        results
      end

    end
  end
end
