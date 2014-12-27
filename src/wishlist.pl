#!/usr/bin/perl -w

use WishList;

my $wishlistSrc="./wishlist.html";
my $wishlistParsed="./wishlist.actual";

print '>> ';
my %oldWishList;
my %newWishList;
while ( 1 ) {
  my $line = <>;
  chomp( $line );
  if ( $line =~ /^q/i ) { # q or quit for exit
    print "Goodbuy!\n";
    exit;
  }

  if ( $line =~ /^h/i ) { # h or help for help
    ( my $message = <<"    END_MESSAGE" ) =~ s/^ {4}//gm;
    q or quit --- exit the script
    h or help --- print this help

    how to work with entire wishlist:
    w update \$nickname --- will download wishlist from steam and compare results with old data if there is one
    w stash --- save old map (if it was loaded) as actual; if map wasn't loaded or is empty - nothing happens
    w save --- save new map (loaded by 'w update' command); if map wasn't loaded or is empty - nothing happens
    w compare --- compare old (from file) and new (loaded in this session) wishlists
    END_MESSAGE
    print $message;
  }
# work with entire wishlist
  if ( $line =~ /^w /i ) {
    my @commands = split / /, $line;
    my $marker = $commands[1];
    if ( $marker eq 'update' ) {
      my $nickname = $commands[2];
      WishList::load_wishlist( $nickname, $wishlistSrc );
      %newWishList = WishList::parse_wishlist( $wishlistSrc );
    } elsif ( $marker eq 'stash' ) {
      print "Try to save old map as actual.\n";
      WishList::save_wishlist( \%oldWishList, $wishlistParsed );
    } elsif ( $marker eq 'save' ) {
      print "Try to save new map as actual.\n";
      WishList::save_wishlist( \%newWishList, $wishlistParsed );
    } elsif ( $marker eq 'compare' ) {
      my $mapSize = scalar keys %newWishList;
      if ( $mapSize == 0 ) {
        print "Load fresh wishlist from Steam first. Use 'w update' command; type 'h' for more information.\n";
        next;
      }
      $mapSize = scalar keys %oldWishList;
      %oldWishList = WishList::read_wishlist( $wishlistParsed ) if $mapSize == 0;
      $mapSize = scalar keys %oldWishList;
      if ( $mapSize == 0 ) {
        print "Something is wrong with old wishlist.\n";
        next;
      }
      WishList::compare_wishlists( \%oldWishList, \%newWishList );
    }
  }

  print '>> ';
}

