# librarian-puppet-simple

This project was created out of my frustration with dependency management in librarian-puppet.

some people need external dependencies. I just need to be able to pin revisions for a collection of modules.

I found the dependency managment features of librarian puppet too heavy for my simple use case.

this project just has one command
```
  librarian-puppet install [--verbose]
```
it iterates through your Puppetfile and installs git sources.

#### Credits
The untar and ungzip method come from https://gist.github.com/sinisterchipmunk/1335041
