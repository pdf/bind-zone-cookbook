# bind-zone

Installs and configures the bind DNS server, and provides a flexible LWRP for
generating zone files. This is not quite ready for prime-time.

## Supported Platforms

Currently this cookbook only supports Debian/Ubuntu/derivatives, contributions
welcome!

## Attributes

TODO

## Usage

### bind-zone::default

Include `bind-zone` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[bind-zone::default]"
  ]
}
```

TODO

## Contributing

1. Fork the repository on Github
2. Create a named feature branch (i.e. `add-new-recipe`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request

## License and Authors

Author:: Peter Fern (<ruby@0xc0dedbad.com>)
