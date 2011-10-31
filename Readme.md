# Netrc

This library reads and writes `.netrc` files.

## API

Read a netrc file:

    n = Netrc.read("sample.netrc")

Read the user's default netrc file (`$HOME/.netrc` on Unix;
`%HOME%\_netrc` on Windows):

    n = Netrc.read

Look up a username and password:

    user, pass = n["api.heroku.com"]

Write a username and password:

    n["api.heroku.com"] = user, newpass
    n.save

Have fun!
