#!/usr/bin/perl -w

use WishList;

print '>> ';
while (<>) {
  chomp;
  if (/^q/i) { # q or quit for exit
    print "Goodbuy!\n";
    exit;
  }

  if (/^h/i) { # h or help for help
    (my $message = <<"    END_MESSAGE") =~ s/^ {4}//gm;
    q or quit --- exit the script
    h or help --- print this help
    - how to work with entire wishlist:
    w update \$nickname --- will download wishlist from steam and compare results with old data if there is one
    END_MESSAGE
    print $message;
  }
# work with entire wishlist
  if (/^w /i) {
    $_ =~ /w ([a-zA-Z]+)/;
    my $marker = $1;
    if ($marker eq 'update') {
      $_ =~ /w (\w+)( (\S+))?/;
      my $nickname = $3;
      print "Try to load fresh wishlist for nickname [$nickname]\n";
      WishList::load_wishlist($nickname);
      WishList::parse_wishlist();
    }
  }

  print '>> ';
}

