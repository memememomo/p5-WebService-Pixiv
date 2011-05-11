package WebService::Pixiv::MyPixiv;
use strict;
use warnings;
use URI;
use Web::Scraper;
use WebService::Pixiv::Illust;

use Class::Accessor::Lite
    rw => [ qw(
       mech
       delay
       id
    ) ];

my $MYPIXIV_URI = 'http://www.pixiv.net/mypixiv_all.php';

my @res = ();

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    bless {
	delay => 1,
	%args,
    }, $class;
}

sub selector {
    my $selector_size = qq|div.two_column_space > h3 > span|;
    my $selector_mypixiv_id = qq|li.list_person > a|;

    scraper {
	process $selector_size, size => 'TEXT',
	process $selector_mypixiv_id, 'mypixiv_id[]' => '@href',
    };
}

sub size {
    my ($self) = @_;

    my $res = $self->_get_res(0);

    my $size = $res->{size};
    my @matches = $size =~ /(\d+)/;

    $matches[0];
}

sub _get_content {
    my ($self, $i) = @_;

    my $uri = URI->new($MYPIXIV_URI);

    if ($i > 0) {
	$uri->query_form(
	    id => $self->id,
	    p => ($i + 1),
 	);
    } else {
	$uri->query_form( id => $self->id );
    }

    my $res = $self->mech->get($uri);
    if ( ! $res->is_success ) {
	die "Can't get content: " . $res->req->uri;
    }
    sleep $self->delay;

    $self->mech->content;
}

sub _get_res {
    my ($self, $i) = @_;

    return $res[$i] if defined $res[$i];

    $res[$i] = $self->selector->scrape(
	$self->_get_content($i), $self->mech->uri
    );
}

sub get {
    my ($self, $i) = @_;

    return if ($i < 0 || $i >= $self->size);

    my $page_num = int($i / 20);
    my $mypixiv_num = $i % 20;

    my $res = $self->_get_res($page_num);

    my $href = $res->{mypixiv_id}->[$mypixiv_num];
    $href =~ /member.php\?id=(\d+)/;

    my $id = $1;

    return $id;
}

1;
