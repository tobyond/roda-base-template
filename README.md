# Roda Application Template

A modern pure ruby, [Roda](https://github.com/jeremyevans/roda) application template with [Phlex](https://github.com/phlex-ruby/phlex) for views, [Sequel](https://github.com/jeremyevans/sequel) ORM, [Esbuild](https://esbuild.github.io/) for javascript and CSS bundling, [Tailwindcss](https://tailwindcss.com/), and [Zeitwerk](https://github.com/fxn/zeitwerk) integration.

## Features

- Roda web framework
- Sequel ORM with PostgreSQL
- Phlex for views
- Esbuild with tailwindcss
- Zeitwerk autoloading
- Database migrations and rake tasks
- Environment-based configuration
- Test setup with Minitest
- Development console with IRB
- Automatic code reloading in development
- Model annotation support

Configured for postgres, but you can use whatever you want.
Out of the box this template has rudimentary authentication (similar to rails authentication generator), although upgrading [rodauth](https://rodauth.jeremyevans.net/) gem is preferable.

## Directory Structure

```
.
├── app/
│   ├── assets/
│       ├── css/
│       └── javascript/
│   ├── models/
│   ├── routes/
│   └── views/
├── config/
│   ├── migrations/
│   ├── application.rb
│   ├── database.rb
│   ├── database.yml
│   └── seeds.rb
├── test/
│   ├── models/
│   ├── routes/
│   └── test_helper.rb
├── .env.rb
├── Gemfile
└── Rakefile
```

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install

   npm install
   ```
3. Configure your database in `config/database.yml`
4. Generate your `ENV['SESSION_SECRET']` in `.env.rb`, a different one for each env:
   ```bash
   ruby -rsecurerandom -e 'puts SecureRandom.base64(64).inspect'
   ```
5. Set up your database environment variables in `.env.rb`
6. Create your databases:
   ```bash
   rake db:create
   rake db:migrate
   ```
7. Start your server:
   ```bash
   foreman start
   ```
8. Visit localhost:9292
9. Customize your app:
   - replace the instances of MyApp with the name of your app.
   - update the database config with your credentials.
   - save to your git repo


## Database Configuration

Configure your database settings in `config/database.yml`:

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5
  host: <%= ENV.fetch('DATABASE_HOST', 'localhost') %>

development:
  <<: *default
  database: my_app_development

test:
  <<: *default
  database: my_app_test

production:
  <<: *default
  database: my_app_production
```

## Environment Variables

Create a `.env.rb` file in your project root:

```ruby
case ENV['RACK_ENV'] ||= 'development'
when 'test'
  ENV['SESSION_SECRET'] ||= "" # needs to be generated, unique, use: SecureRandom.hex(64) in irb
  ENV['DATABASE_USERNAME'] ||= "my_app"
  ENV['DATABASE_PASSWORD'] ||= ""
  ENV['DATABASE_HOST'] ||= "localhost"
when 'production'
  ENV['SESSION_SECRET'] ||= "" # needs to be generated, unique, use: SecureRandom.hex(64) in irb
  ENV['DATABASE_USERNAME'] ||= "my_app"
  ENV['DATABASE_PASSWORD'] ||= "my-complex-password"
  ENV['DATABASE_HOST'] ||= "my-servers-host"
else
  ENV['SESSION_SECRET'] ||= "" # needs to be generated, unique, use: SecureRandom.hex(64) in irb
  ENV['DATABASE_USERNAME'] ||= "my_app"
  ENV['DATABASE_PASSWORD'] ||= ""
  ENV['DATABASE_HOST'] ||= "localhost"
end
```

## Available Rake Tasks

### Database Tasks

```bash
# Database Creation/Dropping
rake db:create                  # Create the database
rake db:drop                    # Drop the database

# Migrations
rake db:migrate                 # Run pending migrations
rake db:migrate[test]           # Run migrations for test environment
rake db:migrate[test,0]         # Migrate down to version 0 for test environment

# Environment Specific Tasks
rake db:test:up                 # Migrate test database up
rake db:test:down              # Migrate test database down
rake db:test:bounce            # Migrate down and back up
rake db:test:reset             # Full reset with seed
rake db:test:force_reset       # Force reset (drops all tables)

# Same commands available for development and production
rake db:development:up
rake db:production:up
# etc...

# Database Reset/Seeding
rake db:reset                   # Reset database (migrate down, up, and seed)
rake db:force_reset            # Force reset database (skips missing migrations)
rake db:seed                    # Load seed data

rake routes                    # rudimentary routes lookin from routes files
```

### Migration Generator

Generate a new migration:

```bash
rake generate:migration[CreateUsers]
```

This creates a timestamped migration file in `config/migrations/`:

```ruby
# config/migrations/YYYYMMDDHHMMSS_create_users.rb
Sequel.migration do
  change do
    # Add migration code here
  end
end
```

### Other Tasks

```bash
rake console                    # Start an interactive console
rake annotate                   # Annotate Sequel models
rake test                      # Run all tests
```

## Zeitwerk Autoloading

The application uses Zeitwerk for autoloading with reloading enabled in development. The following directories are autoloaded:

- `app/models`
- `app/views`

Configuration in `config/application.rb`:

```ruby
def setup_zeitwerk
  @loader = Zeitwerk::Loader.new
  
  loader.push_dir(File.join(Application.root, 'app/models'))
  loader.push_dir(File.join(Application.root, 'app/views'), namespace: Views)
  
  if development?
    require 'listen'
    loader.enable_reloading
    loader.logger = logger
    
    Listen.to(
      'app/models',
      'app/views'
    ) { loader.reload }.start
  end
  
  loader.setup
end
```

## Console

The application includes an IRB console with the application environment loaded:

```bash
rake console
```

In the console, you can:
- Access all your models
- Execute database queries
- Reload code changes with `reload!`
- See SQL queries with custom formatting

## Testing

Tests use Minitest. Run them with:

```bash
rake test
```

Configure your test environment in `test/test_helper.rb`.

## Development

In development mode:
- Code reloading is enabled
- SQL queries are logged
- Zeitwerk logging is enabled

## Production

For production:
- Set appropriate environment variables
- Ensure `RACK_ENV=production`
- Configure database credentials securely

## Deployment

[Dokku](https://dokku.com/) is a fabulous option to deploy to a server.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create new Pull Request

## License

This project is licensed under the MIT License.
