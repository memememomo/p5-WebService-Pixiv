package WebService::Pixiv::MemberIllust;
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

my $MEMBER_ILLUST_URI = 'http://www.pixiv.net/member_illust.php';

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
    my $selector_size = qq|div.two_column_body > h3 > span|;
    my $selector_illust_id = qq|li[id^="li_"] > a|;

    scraper {
	process $selector_size, size => 'TEXT',
	process $selector_illust_id, 'illust_id[]' => '@href',
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

    my $uri = URI->new($MEMBER_ILLUST_URI);
    $uri->query_form( id => $self->id );

    if ($i > 0) {
	$uri->query_form( p => ($i + 1) );
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
    my $Illust_num = $i % 20;

    my $res = $self->_get_res($page_num);

    my $href = $res->{illust_id}->[$Illust_num];
    $href =~ /illust_id=(\d+)/;

    my $id = $1;

    WebService::Pixiv::Illust->new(
	mech => $self->mech,
	id   => $id,
    );
}

1;
