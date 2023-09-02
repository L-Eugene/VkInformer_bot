FROM ruby:3.2

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

CMD ["ruby", "run_bot.rb"]

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'test' && bundle install

COPY . .