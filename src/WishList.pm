package WishList;

use strict;
use warnings;
use diagnostics;
use feature 'say';
use HTML::TokeParser::Simple;
use LWP::Simple;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(load_wishlist parse_wishlist);
%EXPORT_TAGS = ( DEFAULT => [qw(&load_wishlist)],
                 Both    => [qw(&load_wishlist &parse_wishlist)]);

my $wishlistSrc = './wishlist.html';
my $wishlistIds = './wish.list';

sub load_wishlist {
# in: nickname -> http://steamcommunity.com/id/$name/wishlist
  my ($nickname) = @_;

  # if wish.list already exists - remove it, we will make a new one
  if ( -e $wishlistSrc ) {
    say $wishlistSrc.' has already existed - remove it.';
    unlink $wishlistSrc;
  }

  say 'try to load wishlist for user '.$nickname;
  my $url = 'http://steamcommunity.com/id/'.$nickname.'/wishlist';
  my $content = get $url;
  die "Couldn't get $url" unless defined $content;
  open (OUTFILE, '>', $wishlistSrc);
  binmode (OUTFILE, ':utf8');
  print OUTFILE $content;
  close (OUTFILE);
}

sub parse_wishlist {
# parse: <div class='wishlistRow ' id='game_$num'> -> http://store.steampowered.com/app/$num
# <div class='discount_pct'>-$d%</div>
# <div class='discount_final_price'>$price
# or
# <div class='price'>$price
  my $parser = HTML::TokeParser::Simple->new(file => $wishlistSrc);
  open (OUTFILE, '>', $wishlistIds);
  my $gameId=0;
  my %gameMap;
  while ( my $token = $parser->get_token ) { # get every token
    if ( $token->is_start_tag( 'div' ) ) { # pick only <div ...> from every row in wishlist
      my $divClass = $token->get_attr( 'class' );
      if ( length $divClass ) {
        if ( $divClass eq 'wishlistRow ' ) {
          $gameId = $token->get_attr( 'id' );
          $gameId =~ s/game_//;
          say $gameId;
        } elsif ( $divClass eq 'discount_pct' ) {
          # discount
        } elsif ( $divClass eq 'discount_final_price' ) {
          # price with discount
        } elsif ( $divClass eq 'price' ) {
          # just price
        }
      }
    }
  }
  close(OUTFILE);
}

1;
