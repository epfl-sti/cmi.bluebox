
# Basic Schema
```
                          +------------+
  +------------+          | BBXs       |
  | VPNs       |          +------------+
  +------------+          | #bbxid     |
  | #vpnid     | <------- + vpn(title) |
  | title      |          | title      |
  | desc       |          | desc       |
  | create_dt  |          | create_dt  |
  |            |          |            |
  +------------+          +------------+
```

# NOC
Node Operations Controller

  NOC <--[1-1]-- VPNs <--[1-N]-- BBXx
