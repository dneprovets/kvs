# kvs

simple key/value storage written as an example of source code

rebar get-deps
make
make run

Request examples:

http://localhost:8989/create/?key=a&value=s
http://localhost:8989/read/?key=a
http://localhost:8989/update/?key=a&value=b
http://localhost:8989/delete/?key=a
http://localhost:8989/clear/?key=a
