package WebService::Pixiv::Illust;
use strict;
use warnings;
use URI;
use Web::Scraper;
use Class::Accessor::Lite
    rw => [ qw(
       mech
    ) ];

my $ILLUST_URI = 'http://www.pixiv.net/member_illust.php';

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    my $self = bless \%args, $class;
    $self;
}

sub thumbnail {
    my ($self) = @_;
    URI->new($self->res->{image});
}

sub illust {
    my ($self) = @_;
    my $uri = $self->thumbnail;

    $uri =~ s/_m(\.[^.]+)$/$1/;
    URI->new($uri);
}

sub title {
    my ($self) = @_;
    $self->res->{title};
}

sub tags {
    my ($self) = @_;
    $self->res->{tags};
}

sub description {
    my ($self) = @_;
    $self->res->{desc};
}

sub uri {
    my ($self) = @_;

    my $uri = URI->new($ILLUST_URI);

    $uri->query_form(
	mode => 'medium',
	illust_id => $self->{id},
    );

    $uri;
}

sub res {
    my ($self) = @_;

    if ( ! $self->mech->get($self->uri)->is_success ) {
	die "Can't get content: " . $self->res->req->uri;
    }

    my $selector_img   = qq|div.works_display > a > img|;
    my $selector_title = qq|div.works_data > h3|;
    my $selector_tags  = qq|span#tags > a|;
    my $selector_desc  = qq|p.works_caption|;

    scraper {
	process $selector_img, image => ['@src'],
	process $selector_title, title => 'TEXT',
	process $selector_tags, 'tags[]' => 'TEXT',
	process $selector_desc, desc => 'TEXT',
    }->scrape($self->mech->content, $self->mech->uri);
}

1;
