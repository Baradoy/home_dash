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

This is still in early experimental stage.
