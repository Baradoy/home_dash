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

You can add the welcome cards with


```
card = %HomeDash.Card{card_component: HomeDashWeb.Cards.Default, id: 1, order: 4, data: %{title: "My Second Card"}}
HomeDash.WelcomeCardProvider.push_card(card)
card2 = %HomeDash.Card{card_component: HomeDashWeb.Cards.Default, id: 2, order: 3, data: %{title: "My First Card"}}
HomeDash.WelcomeCardProvider.push_card(card2)
```
