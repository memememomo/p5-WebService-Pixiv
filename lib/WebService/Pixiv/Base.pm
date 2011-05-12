package WebService::Pixiv::Base;
use strict;
use warnings;
use URI;
use Web::Scraper;

use Class::Accessor::Lite
    rw => [ qw(
	    mech
	    delay
	    id
            res
    ) ];

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    bless {
	delay => 1,
	res   => [],
	%args,
    }, $class;
}

sub base_uri {
    'http://www.pixiv.net/';
}

sub selector {
    scraper { };
}

sub count {
    my ($self) = @_;

    my $res = $self->_get_res(0);

    my $count = $res->{count};
    my @matches = $count =~ /(\d+)/;

    $matches[0];
}

sub _get_content {
    my ($self, $i) = @_;

    my $uri = URI->new($self->base_uri);

    my %query = ( id => $self->id, $uri->query_form );
    if ($i > 0) {
	$query{p} = $i + 1;
    }

    $uri->query_form( %query );

    my $res = $self->mech->get($uri);
    if ( ! $res->is_success ) {
	die "Can't get content: " . $res->req->uri;
    }
    sleep $self->delay;

    $self->mech->content;
}

sub _get_res {
    my ($self, $i) = @_;

    return $self->res->[$i] if defined $self->res->[$i];

    $self->res->[$i] = $self->selector->scrape(
	$self->_get_content($i),
	$self->mech->uri,
    );
}

sub get {
    my ($self, $i) = @_;

    return if ($i < 0 || $i >= $self->count);

    my $pager = $self->pager;
    my $page_num = int($i / $pager);
    my $item_num = $i % $pager;

    my $res = $self->_get_res($page_num);

    $self->response($res, $item_num);
}

sub response {
    my ($self, $res, $item_num) = @_;
    return $res;
}

1;
