#!/usr/bin/perl -w

use WishList;

my $name=$ARGV[0];
#WishList::load_wishlist($name);
WishList::parse_wishlist();
