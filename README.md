# Arachni WebUI

This is the new Web User Interface for [Arachni](https://github.com/Arachni/arachni).

The interface is under development so depending on when you read this it may just
be a mockup, partially or not at all working.

(This application was generated with the [rails_apps_composer](https://github.com/RailsApps/rails_apps_composer) gem provided by the [RailsApps Project](http://railsapps.github.com/).)

## Features

- Administrators can manage all:
  - Users,
  - Scan configuration Profiles,
  - Scans,
  - Dispatchers.
- Users can:
  - Start Scans using one of the admin-defined Profiles and Dispatchers,
  - Manage, comment, share and export reports of their Scans,
  - See, comment and export reports of Scans which have been shared with them by other users.

- Available Scan types:
  - Direct -- From the WebUI machine to the webapp, no need to setup anything else.
  - Remote (using a Dispatcher) -- From the machine of the Dispatcher to the webapp.
  - Grid (using multiple Dispatchers) -- Using multiple machines to perform
    super-fast, distributed scans.
- Scan reports can be exported in multiple formats (HTML, XML, YAML and more).

## Technical details

### Ruby on Rails

This application is being developed on:

* Ruby version 1.9.3
* Rails version 3.2.8

### Database

This application uses SQLite with ActiveRecord.

### Development

* Template Engine: ERB
* Testing Framework: RSpec and Machinist and Cucumber
* Front-end Framework: Twitter Bootstrap (Sass)
* Form Builder: SimpleForm
* Authentication: Devise
* Authorization: CanCan

## Getting Started

To setup the WebUI run:

```
git clone git://github.com/Arachni/webui.git
cd webui
bundle install
rake db:migrate
rake db:setup
rails s thin
```

## Documentation and Support

For the time being, this is the only documentation.

### Issues

Please send your feedback using Github's issue system at
[http://github.com/Arachni/arachni/issues](http://github.com/Arachni/arachni/issues).

## Contributing

If you make improvements to this application, please share with others.

* Fork the project on GitHub.
* Make your feature addition or bug fix.
* Commit with Git.
* Send a pull request.

## Credits

* [Tasos Laskos](mailto:tasos.laskos@gmail.com)

## License

Arachni WebUI is licensed under the Apache License Version 2.0.<br/>
See the [LICENSE](file.LICENSE.html) file for more information.
