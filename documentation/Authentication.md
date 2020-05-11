# Authentication

The following authentication mechanisms are currently supported:

1. Server password
2. NickServ

Below are details of how each mechanism is implemented.

## 1. Server Password

After establishing the socket connection to the server, the following messages are sent to the server:

```
PASS [password]
NICK [nickname]
USER [username] 0 * :[realname]
MODE [username] [mode]
```

## 2. NickServ

After establishing the socket connection to the server, the following messages are sent to the server:

```
NICK [nickname]
USER [username] 0 * :[realname]
MODE [username] [mode]
NickServ identify [password]
```

Note that this assumes the user has already registered with:

```
/msg nickserv register [password] [email]
```