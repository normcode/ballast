# Ballast

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `plug_load_balancer` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ballast, "~> 0.1.0"}]
    end
    ```

  2. Ensure `plug_load_balancer` is started before your application:

    ```elixir
    def application do
      [applications: [:ballast]]
    end
    ```
