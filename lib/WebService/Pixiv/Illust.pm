package WebService::Pixiv::Illust;
use strict;
use warnings;
use URI;
use Web::Scraper;
use WebService::Pixiv::Illust::BookmarkDetail;
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

sub data {
    my ($self) = @_;
    $self->res->{data};
}

sub page_count {
    my $self = shift;

    return $self->{page_count} if defined $self->{page_count};

    if ($self->data =~ /(\d+)P/) {
	$self->{page_count} = $1;
	return $self->{page_count};
    } else {
	return 0;
    }
}

sub thumbnail {
    my ($self) = @_;
    URI->new($self->res->{image});
}

sub illust {
    my ($self, $page) = @_;
    my $uri = $self->thumbnail;

    if ($self->page_count) {
	$page ||= 0;
	if ($page < 0 || $page + 1 > $self->page_count) {
	    $page = 0;
	}
	$uri =~ s/_m(\.[^.]+)$/_p$page$1/;
    } else {
	$uri =~ s/_m(\.[^.]+)$/$1/;
    }

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

sub bookmark_detail {
    my ($self) = @_;
    WebService::Pixiv::Illust::BookmarkDetail->new(
	mech      => $self->mech,
	illust_id => $self->{id},
    );
}

sub download {
    my ($self, $page) = @_;

    return $self->mech->get(
	$self->illust($page),
    );
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
    my $selector_data  = qq|div.works_data > p|;
    my $selector_title = qq|div.works_data > h3|;
    my $selector_tags  = qq|span#tags > a[href^="tags.php"]|;
    my $selector_desc  = qq|p.works_caption|;

    scraper {
	process $selector_img, image => ['@src'],
	process $selector_data, data => 'TEXT',
	process $selector_title, title => 'TEXT',
	process $selector_tags, 'tags[]' => 'TEXT',
	process $selector_desc, desc => 'TEXT',
    }->scrape($self->mech->content, $self->mech->uri);
}


1;
