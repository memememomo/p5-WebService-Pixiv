package WebService::Pixiv::Illust::BookmarkDetail;
use strict;
use warnings;
use URI;
use Web::Scraper;
use Class::Accessor::Lite
    rw => [ qw(
       mech
    ) ];

my $BOOKMARK_DETAIL_URI = 'http://www.pixiv.net/bookmark_detail.php';


sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    bless \%args, $class;
}

sub bookmark_num {
    my ($self) = @_;
    my $bookmark_num = $self->res->{bookmark_num};
    $bookmark_num =~ /(\d+)/;
    return $1;
}

sub bookmark_members {
    my ($self) = @_;

    my @members;
    for my $member ( @{$self->res->{bookmark_members}} ) {
	$member =~ /member.php\?id=(\d+)/;
	push @members, $1;
    }

    return \@members;
}

sub uri {
    my ($self) = @_;

    my $uri = URI->new($BOOKMARK_DETAIL_URI);

    $uri->query_form(
	illust_id => $self->{illust_id},
    );
    $uri;
}

sub res {
    my ($self) = @_;

    if ( ! $self->mech->get($self->uri)->is_success ) {
	die "Can't get content: " . $self->res->req->uri;
    }

    my $selector_bookmark_num = qq|div.bookmark_detail_body > h3 > span|;
    my $selector_bookmark_members = qq|div.bookmark_detail_body > ul > li > a|;

    scraper {
	process $selector_bookmark_num, bookmark_num => 'TEXT',
	process $selector_bookmark_members, 'bookmark_members[]' => '@href',
    }->scrape($self->mech->content, $self->mech->uri);
}

1;
