# Install ruby version 2.6.1
* rbenv install 2.6.5 && rbenv global 2.6.5 && rbenv rehash

# Install bundle
* mkdir -p .bundle
* bundle install --path .bundle

# Run
bundle exec rspec spec/feature/checkout_spec.rb
