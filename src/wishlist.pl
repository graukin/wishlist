#!/usr/bin/perl -w

use WishList;

while (1) {
  print '>> ';
  chomp($_ = <>);
  if (/^q/i) { # q or quit for exit
    print "Goodbuy!\n";
    exit;
  }

  if (/^h/i) { # h or help for help
    print "q or quit --- exit the script\n";
    print "h or help --- print this help\n";
  }
}
#my $name=$ARGV[0];
#WishList::load_wishlist($name);
#WishList::parse_wishlist();
