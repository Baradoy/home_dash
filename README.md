# HomeDash

HomeDash provides a standardized way of presenting dashboard cards from various services.

This is still in early experimental stage.

## Setup

### Configuration

#### Starting the Provider servers yourself

You may want to start the Providers in your application, say for example if you have a provider that relys in another GenServer (like PubSub.)

```elixir
config :home_dash, servers: false
```

### Hello World

HomeDash can be up and running with the example Welcome card provider by adding the following to the router:

```elixir
scope "/home_dash", HomeDashWeb do
  pipe_through [:browser]

  live_session :cards, layout: {MyAppWeb.Layouts, :app} do
    live "/cards", CardsLive, :my_action
  end
end
```

Now the welcome cards will be at `/home_dash/cards`.

### Configuring Providers

You can change the card providers in your config with the following:

```elixir
config :home_dash,
  actions: [
    my_action: [{HomeDash.Providers.BrewDashTaps, [taps_url: "https://example.com/api/taps"]}]
  ]
```

Now the [BrewDash](https://github.com/hez/brew-dash) cards will be at `/home_dash/cards`.

### Multiple Providers

Multiple providers can be configured for the same live action

```elixir
config :home_dash,
  actions: [
    my_action: [
      HomeDash.Providers.Welcome,
      {HomeDash.Providers.BrewDashTaps, [taps_url: "https://example.com/api/taps"]}
    ]
  ]
```

Similarly, there can be multiple live actions

```elixir
config :home_dash,
  actions: [
    welcome: [HomeDash.Providers.Welcome]
    brewdash: [
        {HomeDash.Providers.BrewDashTaps, [taps_url: "https://example.com/api/taps"]}
    ]
  ]
```

### Config options

* `:server_name` - Define the name that the server will be registered under. Defaults to the provider module name, e.g. `HomeDash.Providers.Welcome`. This is required if you have one provider that will be used with more than one configuration.

* `:sort_priority` - The integer value to be added to cards before sorting. Use this to push cards earlier or later in the sort order.


### Layout

Consider the spacing in your app layout (`MyAppWeb.Layouts`, `app.html.heex`). It is not uncommon to have `class="mx-auto max-w-2xl"` on your container `div` inside of `app.html.heex`, but for HomeDash, that may give you an overly restrictive container div. Removing width restrictions for your container div may provide better results.

### Tailwind

Since HomeDash requires Tailwind CSS, and Tailwind purges CSS classes it is not familair with, you will need to add HomeDash to your tailwind.config.js:

```
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/my_project_web.ex",
    "../lib/my_project_web/**/*.*ex",
    "../deps/home_dash/lib/home_dash_web.ex",
    "../deps/home_dash/lib/home_dash_web/**/*.*ex"
  ],
```

### Welcome Card Provider

The welcome card provider is an example implementation.

You can add additional welcome cards with:

```
HomeDash.Providers.Welcome.push_cards(%HomeDash.Card{
  card_component: HomeDashWeb.Cards.Default,
  id: UUID.uuid4(),
  order: 4,
  data: %{title: "My New Card"}
})
```
