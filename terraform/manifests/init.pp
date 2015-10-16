# Deploy a flat Terraform installation. 
class terraform(
  $terraform_ensure       = 'present',
  $terraform_base_dir     = hiera('terraform::base_dir'),
  $terraform_owner        = hiera('terraform::owner'),
  $terraform_download_uri = hiera('terraform::download_uri'),
) {
  # Required default path for exec calls
  Exec {path => ['/bin', '/usr/bin', '/usr/sbin', '/sbin']}
  #
  # Download and unpack Terraform to $terraform_base_dir
  case $terraform_ensure {
    'present': {
      $install_command = join([
        "curl -L ${terraform_download_uri} > /tmp/terraform.zip",
        "unzip -o /tmp/terraform.zip -d ${terraform_base_dir}",
        "chown -R ${terraform_owner} ${terraform_base_dir}",
        # TODO: move to /files/terraform.sh
        # lint:ignore:80chars lint:ignore:single_quote_string_with_variables
        'echo "export PATH=\${PATH}:/opt/terraform\n" > /etc/profile.d/terraform.sh'
        # lint:endignore
      ], ' && ')
      exec { "Create ${terraform_base_dir}.":
          command => "/bin/mkdir -p ${terraform_base_dir}",
          creates => $terraform_base_dir
      } ->
      exec { 'Install Terraform binaries.':
          command => $install_command,
          unless  => "test -x ${terraform_base_dir}/terraform",
          user    => $terraform_owner,
          umask   => '0027',
      }
    }
    #
    # Remove Terraform if $terraform_ensure is anything other than 'present'.
    default: {
      file { $terraform_base_dir:
        ensure  => false,
        backup  => false,
        recurse => true,
        force   => true,
      }
      file { '/etc/profile.d/terraform.sh':
        ensure  => false,
      }
    }
  }
}

