# HomeDash

HomeDash provides a standardized way of presenting dashboard cards from various services.

```
scope "/home_dash", HomeDashWeb do
  pipe_through [:browser]

  live_session :cards, layout: {MyAppWeb.Layouts, :app} do
    live "/cards", CardsLive
  end
end
```

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

This is still in early experimental stage.

You can add additional welcome cards with:


```
HomeDash.WelcomeCardProvider.push_card(%HomeDash.Card{
  card_component: HomeDashWeb.Cards.Default,
  id: UUID.uuid4(),
  order: 4,
  data: %{title: "My New Card"}
})
```
