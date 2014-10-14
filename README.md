Foreman backend for Hiera
=========================
[Hiera backend][1] which uses [external_node_v2][2] to collect information
from Foreman.

How to use
----------
Hiera is running and configured **only** on Puppet Master which is a Foreman
smart proxy. The proxy is configured and working with Foreman.

1. Configure external_node_v2.rb.

    1. edit /etc/puppet/foreman.yaml:

            :url: "http://foreman:3000"
            :puppetdir: "/var/lib/puppet"
            :facts: true
            :storeconfigs: true
            :timeout: 3

    2. Test exteranl_node_v2.rb :

            /etc/puppet/external_node_v2.rb my.node.example.com

2. Add the backend `/lib/hiera/foreman_backend.rb` to hiera.
     - __RHEL__ `/usr/lib/ruby/site_ruby/1.8/hiera/backend/`
     - __Fedora__ `/usr/share/ruby/vendor_ruby/hiera/backend/`

3. Add Hiera configurations `hiera.yaml` (use symbolic link on of the files):

        /etc/hiera.yaml
        /etc/puppet/hiera.yaml

    **Notes**:

    1. Look at the [example][3] for reference. Hiera resolves the parameters
    `%{::fqdn}` and `%{environment}` using the facts which puppet agent sends.

    2. `%{environment}` is not defualt fact , you have to add it yourself
     **before** running agent. Add the [plugin to the environment][4] and on the
     node run:

            puppet agent --pluginsync

    3. Puppet Master loads `hiera.yaml` only once. Thus you can have one `hiera.yaml`.

4. Test Hiera on Puppet Master:

        hiera -c /etc/puppet/hiera.yaml -y \
        /var/lib/puppet/yaml/facts/my.node.example.com.yaml ntp::servers --debug

    The file `/var/lib/puppet/yaml/facts/my.node.example.com.yaml` contain facts
    that node sent on last puppet agent run.

5. Make sure the environment has `manifests\site.pp` with the following content:

        hiera_include('classes')

    This tells any node which uses that environment to include all classes.
    Add classes with Foreman or Hiera.

[1]: https://docs.puppetlabs.com/hiera/1/custom_backends.html
[2]: https://github.com/theforeman/puppet-foreman/blob/master/files/external_node_v2.rb
[3]: https://github.com/abraverm/foreman-backend/blob/master/hiera.yaml
[4]: https://docs.puppetlabs.com/guides/plugins_in_modules.html
