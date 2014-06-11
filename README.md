# bind-lwrp

Installs and configures the bind DNS server, and provides a flexible LWRP for
generating zone files.

## Supported Platforms

Currently this cookbook only supports Debian/Ubuntu/derivatives, contributions
welcome!

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['bind-lwrp']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

## Usage

### bind-lwrp::default

Include `bind-lwrp` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[bind-lwrp::default]"
  ]
}
```

## Contributing

1. Fork the repository on Github
2. Create a named feature branch (i.e. `add-new-recipe`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request

## License and Authors

Author:: Peter Fern (<ruby@0xc0dedbad.com>)
