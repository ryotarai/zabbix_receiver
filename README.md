# ZabbixReceiver

```
+--------------+       +-----------------+             +-----------------------+
|              |       |                 |             |                       |
| Zabbix Agent +-------> zabbix_receiver +-------------> Output (like Fluentd) |
|              |       |                 | sender data |                       |
+--------------+       +----------+------+             +-----------------------+
                                  |                                             
                                  |      +---------------+                      
                                  |      |               |                      
                                  +------> Zabbix Server |                      
                           active checks |               |                      
                                         +---------------+                      
```

## Installation and Usage

See:

- https://github.com/ryotarai/zabbix_receiver-fluentd

## Contributing

1. Fork it ( https://github.com/[my-github-username]/zabbix_receiver/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
