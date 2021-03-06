package WishList;

use warnings;
use strict;
use feature 'say';
use HTML::TokeParser::Simple;
use LWP::Simple;
use Term::ANSIColor;
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
          $dText =~ s/[^0-9]//g;
          $discount = $dText;
        } elsif ( $divClass eq 'discount_final_price' or $divClass eq 'price' ) {
          # price with discount or without
          $token = $parser->get_token;
          my @dToken = split / /, $token->as_is;
          my $sToken = $dToken[0];
          $sToken =~ s/[^0-9]//g;
          $price = $sToken unless $sToken eq "";
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
  my %onlyOld;
  my %onlyNew;
  my %priceUp;
  my %priceDown;
  my %priceEq;
  my %tempCnt;
  foreach my $key ( keys %$oldMap, %$newMap ) {
    $tempCnt{$key} ++;
  }
  foreach my $key ( keys %tempCnt ) {
    if ( $tempCnt{$key} == 1 ) {
      if ( exists $oldMap->{$key} ) {
        $onlyOld{$key} = $oldMap->{$key};
      } elsif ( exists $newMap->{$key} ) {
        $onlyNew{$key} = $newMap->{$key};
      }
    } else {
      if ( $oldMap->{$key}->{'price'} > $newMap->{$key}->{'price'} ) {
        $priceDown{$key} = $newMap->{$key};
        $priceDown{$key}->{'old_price'} = $oldMap->{$key}->{'price'};
      } elsif ( $oldMap->{$key}->{'price'} < $newMap->{$key}->{'price'} ) {
        $priceUp{$key} = $newMap->{$key};
        $priceUp{$key}->{'old_price'} = $oldMap->{$key}->{'price'};
      } else {
        $priceEq{$key} = $newMap->{$key};
      }
    }
  }
# print items from old list only
  print colored ( "===== Disappear from list:\n", 'yellow' );
  print_map(\%onlyOld, 'reset');
# print items from new list only
  print colored ( "===== Appear in list:\n", 'yellow' );
  print_map(\%onlyNew, 'reset');
# print items with price lower than earlier
  print colored ( "===== Low price!!!\n", 'yellow' );
  print_map(\%priceDown, 'green on_black');
# print items with price higher than earlier
  print colored ( "===== High price :(\n", 'yellow' );
  print_map(\%priceUp, 'red on_black');
# print items with the same price
  print colored ( "===== Nothing changes\n", 'yellow' );
  print_map(\%priceEq, 'reset');
}

##################### work with data map #########################
sub print_map {
  my ( $mapRef, $color ) = @_;
  while( my( $k, $v ) = each %$mapRef )
  {
    print "$k :: '$v->{'name'}' ";
    print colored ( "$v->{'old_price'} -> ", $color ) if ( exists $v->{'old_price'} and $v->{'old_price'} != 0 );
    print colored ( "$v->{'price'}", $color );
    print " (-$v->{'discount'}%)" if ( exists $v->{'discount'} and $v->{'discount'} != 0 );
    print "\n";
  }
}

1;
