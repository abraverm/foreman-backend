# Foreman Backend for Hiera

class Hiera
  module Backend
    class Foreman_backend
      def initialize
      end

      def lookup(key, scope, order_override, resolution_type)
        fqdn    = scope['fqdn']
        Hiera.debug("Performing Foreman ENC lookup on #{fqdn} for #{key}")
        results = nil

        foreman = YAML.load(`/etc/puppet/external_node_v2.rb #{fqdn}`)
        Hiera.debug("Imported Foreman yaml: #{foreman}")

        unless foreman.nil?
          begin
          case key
          when 'environment'
            if foreman['environment'] then
              results = foreman['environment']
              Hiera.debug("Found environment '#{results}' in Foreman")
            else
              Hiera.debug("Didn't find environment in Foreman")
            end
          when 'classes'
            if foreman['classes'] then
              results = foreman['classes'].keys
              Hiera.debug("Adding the following classes from Foreman: #{results}")
            else
              Hiera.debug("No classes added in Foreman")
            end
          when 'parameters'
            if foreman['parameters'] and foreman['parameters'].has_key?(key) then
              Hiera.debug("Found key in Foreman parameters")
              results = foreman['parameters'][key]
            else
              Hiera.debug("Foreman doesn't have such key in parameters")
            end
          else
            if foreman['classes'] then
              class_params = foreman['classes']
              key_array = key.split("::")
              key_class = key_array[0..-2].join("::")
              key_var = key_array.last
              if class_params.has_key?(key_class) then
                key_vars = class_params[key_class]
                if key_vars.has_key?(key_var) then
                  Hiera.debug("Found key in Foreman classes")
                  results = key_vars[key_var]
                else
                  Hiera.debug("Found '#{key_vars}' in Foreman but not '#{key_var}'")
                end
              else
                Hiera.debug("Key '#{key_class}' not found in Foreman class parameters #{class_params}")
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