
# Basic Schema
                          +------------+
  +------------+          | BBXs       |
  | VPNs       |          +------------+
  +------------+          | #bbxid     |
  | #vpnid     | <------- + vpn(title) |
  | title      |          | title      |
  | detail     |          | detail     |
  | create_dt  |          | create_dt  |
  |            |          |            |
  +------------+          +------------+


# NOC
Node Operations Controller

  NOC <--[1-1]-- VPNs <--[1-N]-- BBXx