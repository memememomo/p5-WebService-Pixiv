package WebService::Pixiv::BookmarkUser;
use strict;
use warnings;
use URI;
use Web::Scraper;
use Class::Accessor::Lite
    rw => [ qw(
       mech
       delay
       user_id
    ) ];

my $BOOKMARK_USER = 'http://www.pixiv.net/bookmark.php?type=user';

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
    my $selector_size = qq|div.two_column_top3 > h3 > span|;
    my $selector_user_id = qq|input[name="id[]"]|;

    scraper {
	process $selector_size, size => 'TEXT',
	process $selector_user_id, 'user_id[]' => '@value',
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

    my $uri = URI->new($BOOKMARK_USER);

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

    my $page_num = int($i / 50);
    my $Illust_num = $i % 50;

    my $res = $self->_get_res($page_num);

    return $res->{user_id}->[$Illust_num];
}

1;
