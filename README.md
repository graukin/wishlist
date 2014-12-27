## What is it?

Simple console util for working with Steam's wishlist. It can:
* get fresh wishlist from web for given user
* save this wishlist (parsed) or save only old version (read from file)
* compare new and old versions and print smartdiff: disappeared and suddenly appeared titles, changes in prices and the rest titles which have no changes
* 
## How to use it?

For example there is a user with ID $nickname (I've checked - on the moment of posting this there was no such user).
```
>> w update $nickname
```
this will send a request to Steam's servers and try to get a wishlist (html), than parse it and get information about each title: id, name, current price (with discount), discount value (if it has one)
```
>> w save
```
if it is first time we use this util, we have no other option but to save wishlist for further usage. It's a good case to do it every time before quiting app
```
>> w compare
```
if we've already had saved data from previous start (and we hope that there are some changes in discounts), we should call this command (but not forget to get fresh list before, without saving, just for keeping it in memory). It will compare list in memory (from update) and list on disk (that was saved by 'w save' earlier) and print 5 blocks of titles: appear in new list, disappear from old list, prices go up, prices go down, prices don't change.
```
>> q
```
ok, it's simple, just exit to your command line. Do not forget to save new list before.

## Additional packages

* [HTML::TokeParser::Simple](http://search.cpan.org/~ovid/HTML-TokeParser-Simple-3.16/lib/HTML/TokeParser/Simple.pm) - html parsing
* [LWP::Simple](http://search.cpan.org/~mschilli/libwww-perl-6.08/lib/LWP/Simple.pm) - send request and get html page from remote server
* [Term::ANSIColor](http://search.cpan.org/~rra/Term-ANSIColor-4.03/lib/Term/ANSIColor.pm) - I like to color words ^^
* [JSON](http://search.cpan.org/~makamaka/JSON-2.90/lib/JSON.pm) - serialize parsed data in json to save it on disk and deserialize when reading it back
