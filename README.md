# librarian-puppet-simple

This project was created out of my frustration with dependency management in librarian-puppet, some people need external dependencies, I just need to be able to pin revisions for a collection of modules, and I found the dependency management features of librarian-puppet too heavy for my simple use case.

This project just has fewer commands, but they should be compatible with the original librarian-puppet:

### Clean
Remove the directory where the modules will be installed. At the moment the supported options are:
* `--verbose` display progress messages
* `--path` override the default `./modules` where modules will be installed

```
  librarian-puppet clean [--verbose] [--path]
```

### Install
Iterates through your Puppetfile and installs git sources. At the moment the supported options are:
* `--verbose` display progress messages
* `--clean` remove the directory before installing modules
* `--path` override the default `./modules` where modules will be installed
* `--puppetfile` override the default `./Puppetfile` used to find the modules

```
  librarian-puppet install [--verbose] [--clean] [--path] [--puppetfile]
```

### Update
Iterates through your Puppetfile and updates git sources. If a SHA-1 hash is specified in the `:ref`, the module will not be updated.

Supported options are:<br/>
<li>`--verbose` display progress messages</li>
<li>`--path` override the default `./modules` where modules will be installed</li>
<li> `--puppetfile` override the default `./Puppetfile` used to find the modules</li>

```
  librarian-puppet update [--verbose] [--path] [--puppetfile]
```

## Puppetfile
The processed Puppetfile may contain two different types of modules, `git` and `tarball`. The `git` option accepts an optional `ref` parameter.

The module names can be namespaced, but the created directory will only contain the last part of the name. For example, a module named `puppetlabs/ntp` will generate a directory `ntp`, and so will a module simply named `ntp`.

Here's an example of a valid Puppetfile showcasing all valid options:

```
mod "puppetlabs/ntp",
    :git => "git://github.com/puppetlabs/puppetlabs-ntp.git",
    :ref => "99bae40f225db0dd052efbf1d4078a21f0333331"

mod "apache",
    :tarball => "https://forge.puppetlabs.com/puppetlabs/apache/0.6.0.tar.gz"
```

## Setting up for development and running the specs
Just clone the repo and run the following commands:
```
bundle exec install --path=vendor
bundle exec rspec
```

Beware that the functional tests will download files from GitHub and PuppetForge and will break if either is unavailable.

## License

See [LICENSE](/LICENSE)

## Credits
The untar and ungzip methods came from https://gist.github.com/sinisterchipmunk/1335041