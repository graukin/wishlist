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
# <h4>$gameName</h4>
# <div class='discount_pct'>-$d%</div>
# <div class='discount_final_price'>$price
# or
# <div class='price'>$price
  my $parser = HTML::TokeParser::Simple->new(file => $wishlistSrc);
  open (OUTFILE, '>', $wishlistIds);
  my $gameId=0;
  my $gameName = '';
  my $discount = 0;
  my $price = 0;
  my %gameMap;
  while ( my $token = $parser->get_token ) { # get every token
    if ( $token->is_start_tag( 'div' ) ) { # pick only <div ...> from every row in wishlist
      my $divClass = $token->get_attr( 'class' );
      if ( length $divClass ) {
        if ( $divClass eq 'wishlistRow ' ) {
          if ($gameId != 0) {
            $gameMap{$gameId}->{'name'} = $gameName;
            $gameMap{$gameId}->{'discount'} = $discount;
            $gameMap{$gameId}->{'price'} = $price;
            $gameName = '';
            $discount = 0;
            $price = 0;
          }
          $gameId = $token->get_attr( 'id' );
          $gameId =~ s/game_//;
        } elsif ( $divClass eq 'discount_pct' ) {
          # discount
          $token = $parser->get_token;
          my $dText = $token->as_is;
          $dText =~ /-(\d+)%/;
          $discount = $1;
        } elsif ( $divClass eq 'discount_final_price' or $divClass eq 'price' ) {
          # price with discount or without
          $token = $parser->get_token;
          my $dToken = $token->as_is;
          $dToken =~ /^(\d+)/g;
          $price = $1;
        }
      }
    } elsif ( $token->is_start_tag( 'h4' ) ) { # possibly it's name
      $token = $parser->get_token;
      $gameName = $token->as_is;
    }
  }
  if ($gameId != 0) {
    $gameMap{$gameId}->{'name'} = $gameName;
    $gameMap{$gameId}->{'discount'} = $discount;
    $gameMap{$gameId}->{'price'} = $price;
  }
  printMap(\%gameMap);
  close(OUTFILE);
}

##################### work with data map #########################
sub printMap {
  my ($mapRef) = @_;
  while(my($k, $v) = each %$mapRef)
  {
    my $message = $k." :: '".$v->{'name'}."' ".$v->{'price'};
    $message .=" (-".$v->{'discount'}."%)" unless $v->{'discount'} == 0;
    say $message;
  }
}

1;
