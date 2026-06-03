# Castle demo application: Ruby on Rails

This project demonstrates how to integrate [Castle](https://castle.io) into a
real Ruby on Rails application. It is built on Rails 8.1 with Devise for
authentication and uses the [castle-rb](https://github.com/castle/castle-ruby)
SDK (8.x).

## What's demonstrated

- **login** – successful logins are scored with the `risk` endpoint; failed
  logins are sent to `filter`. The returned verdict (`allow`, `challenge` or
  `deny`) drives whether the session is allowed.
- **logout & profile updates** – recorded with the non-blocking `log` endpoint.
- **Twitter/X OAuth login** – the same risk assessment applied to social sign-in.
- **webhooks** – incoming Castle webhooks are signature-verified with
  `Castle::Webhooks::Verify` and listed in the app.
- **browser SDK** – the `@castleio/castle-js` SDK mints a request token in the
  browser that is submitted with the login form and forwarded to the API.

## Prerequisites

You'll need a Castle account. If you don't have one, start a free trial at
https://castle.io. From the dashboard (Settings → API) you'll need:

- your **publishable key** (`pk`) – used by the browser SDK
- your **API secret** – used by the backend SDK

## Running locally

This app targets **Ruby 3.4** (see `.ruby-version`).

Clone the repo and install dependencies:

```bash
git clone https://github.com/castle/castle-ruby-example.git
cd castle-ruby-example
bundle install
```

Configure your environment and database:

```bash
cp .env.example .env        # then fill in CASTLE_API_SECRET and CASTLE_PK
cp config/database.yml.example config/database.yml
bin/rails db:prepare
```

Run the app:

```bash
bin/rails server
# => http://127.0.0.1:3000
```

`bin/setup` runs the dependency install, file copying and database setup in one
step.

## Styling (Tailwind CSS)

The UI is styled with [Tailwind CSS](https://tailwindcss.com) via the
[`tailwindcss-rails`](https://github.com/rails/tailwindcss-rails) gem (no Node
toolchain required). The source is `app/assets/stylesheets/application.tailwind.css`
with design tokens in `config/tailwind.config.js`; it compiles to
`app/assets/builds/tailwind.css`, which is committed so `bin/rails server` works
without a build step.

If you change the views or the Tailwind source, regenerate the stylesheet:

```bash
bin/rails tailwindcss:build      # one-off build
bin/rails tailwindcss:watch      # rebuild on change during development
```

`assets:precompile` (used by the Docker build) runs `tailwindcss:build`
automatically.

## Configuration

All configuration is read from environment variables (loaded from `.env` in
development and test via `dotenv-rails`):

| Variable             | Purpose                                              |
| -------------------- | ---------------------------------------------------- |
| `CASTLE_API_SECRET`  | Server-side API secret used by the `castle-rb` SDK.  |
| `CASTLE_PK`          | Publishable key used by the browser SDK.             |
| `TWITTER_APP_ID`     | Optional – enables the Twitter/X OAuth login button. |
| `TWITTER_SECRET`     | Optional – Twitter/X OAuth secret.                   |
| `SECRET_KEY_BASE`    | Required in production only.                          |

## Running the tests

```bash
bundle exec rspec
```

## Running with Docker

The bundled `Dockerfile` is a multi-stage build that compiles assets and runs
the app with Puma as an unprivileged user on port 3000. The SQLite database is
created on first boot.

Build the image:

```bash
docker build -t castle-demo-ruby .
```

Run a container, passing your Castle credentials:

```bash
docker run -d -p 4006:3000 \
  -e CASTLE_API_SECRET=YOUR_API_SECRET \
  -e CASTLE_PK=YOUR_PUBLISHABLE_KEY \
  castle-demo-ruby
```

The app will be available at http://127.0.0.1:4006. A `SECRET_KEY_BASE` is
generated automatically if you don't supply one (set it explicitly to keep
sessions across restarts).

## Disclaimer

This sample app is shared in the hope that other developers find it useful.
Although it is not an officially supported sample, we welcome questions and
suggestions at `support@castle.io`.
