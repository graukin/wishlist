package WishList;

use strict;
use warnings;
use diagnostics;
use feature 'say';
use HTML::TokeParser::Simple;
use LWP::Simple;
use JSON;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(load_wishlist parse_wishlist save_wishlist read_wishlist compare_wishlists);
%EXPORT_TAGS = ( DEFAULT => [qw(&load_wishlist)] );

sub load_wishlist {
# in: nickname -> http://steamcommunity.com/id/$name/wishlist
  my ( $nickname, $path ) = @_;

  # if wish.list already exists - remove it, we will make a new one
  if ( -e $path ) {
    say "$path has already existed - remove it.";
    unlink $path;
  }

  say "try to load wishlist for user $nickname";
  my $url = 'http://steamcommunity.com/id/'.$nickname.'/wishlist';
  my $content = get $url;
  die "Couldn't get $url" unless defined $content;
  open ( OUTFILE, '>', $path );
  binmode ( OUTFILE, ':utf8' );
  print OUTFILE $content;
  close ( OUTFILE );
}

sub parse_wishlist {
# parse: <div class='wishlistRow ' id='game_$num'> -> http://store.steampowered.com/app/$num
# <h4>$gameName</h4>
# <div class='discount_pct'>-$d%</div>
# <div class='discount_final_price'>$price
# or
# <div class='price'>$price
  my ( $path ) = @_;
  my $parser = HTML::TokeParser::Simple->new( file => $path );
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
          if ( $gameId != 0 ) {
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
  if ( $gameId != 0 ) {
    $gameMap{$gameId}->{'name'} = $gameName;
    $gameMap{$gameId}->{'discount'} = $discount;
    $gameMap{$gameId}->{'price'} = $price;
  }
  print_map( \%gameMap );
  return %gameMap;
}

sub save_wishlist {
  my ( $wishMapRef, $path ) = @_;
  my $mapSize = scalar keys %$wishMapRef;
  say "Map size = $mapSize";
  if ( $mapSize == 0 ) {
    say "Something has gone wrong. Nothing was saved.";
    return;
  }
  my $jsonText = encode_json $wishMapRef;
  open ( OUTFILE, '>', $path );
  print OUTFILE $jsonText;
  close( OUTFILE );
  say "Map saved.";
}

sub read_wishlist {
  my ( $path ) = @_;
  open( INFILE, '<', $path );
  my $jsonText   = <INFILE>;
  my $wishMapRef = decode_json( $jsonText );
  return %$wishMapRef;
}

sub compare_wishlists {
  my ( $oldMap, $newMap ) = @_;
}

##################### work with data map #########################
sub print_map {
  my ( $mapRef ) = @_;
  while( my( $k, $v ) = each %$mapRef )
  {
    my $message = "$k :: '$v->{'name'}' $v->{'price'}";
    $message .=" (-$v->{'discount'}%)" unless $v->{'discount'} == 0;
    say $message;
  }
}

1;
