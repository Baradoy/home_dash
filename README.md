# HomeDash

HomeDash provides a standardized way of presenting dashboard cards from various services.

This is still in early experimental stage.

### Router and Layout

```
scope "/home_dash", HomeDashWeb do
  pipe_through [:browser]

  live_session :cards, layout: {MyAppWeb.Layouts, :app} do
    live "/cards", CardsLive
  end
end
```

Consider the spacing in your app layout. It is not uncommon to have `class="mx-auto max-w-2xl"` on your container `div` inside of `app.html.heex`, but for HomeDash, that may give you an overly restrictive container div. Removing width restrictions for your container div may provide better results.

### Additional Servers

Include the card provider servers to be started. By default, WelcomeCardProvider and BrewDashProvider will be started. You can add additional card providers from outside of homedash. E.g.:
```
# Configure HomeDash servers
config :home_dash, :servers, [HomeDash.WelcomeCardProvider, {MyApp.WaterPlantsProvider, []}]
```

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
HomeDash.WelcomeCardProvider.push_card(%HomeDash.Card{
  card_component: HomeDashWeb.Cards.Default,
  id: UUID.uuid4(),
  order: 4,
  data: %{title: "My New Card"}
})
```
