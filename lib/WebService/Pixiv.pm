package WebService::Pixiv;
use strict;
use warnings;
use WWW::Mechanize;
use WebService::Pixiv::Illust;
use WebService::Pixiv::MemberIllust;
use WebService::Pixiv::MyPixiv;
use WebService::Pixiv::BookmarkIllust;
use WebService::Pixiv::BookmarkUser;
use WebService::Pixiv::Search;

use Class::Accessor::Lite
    rw => [ qw(
       mech
       delay
       pixiv_id
       password
    ) ];


our $VERSION = '0.01';

my $HOST      = 'www.pixiv.net';
my $BASE_URI  = "http://$HOST";
my $LOGIN_URI = "$BASE_URI/";
my $PROFILE_URI = "$BASE_URI/profile.php";
my $MEMBER_URI = "$BASE_URI/member.php";

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    my $self = bless {
	mech => WWW::Mechanize->new,
	delay => 1,
	%args,
    }, $class;

    if ($self->pixiv_id && $self->password) {
	$self->login();
    }

    $self;
}

sub login {
    my ($self, $pixiv_id, $password) = @_;

    $pixiv_id ||= $self->pixiv_id;
    $password ||= $self->password;

    if ($pixiv_id && $password) {
	$self->mech->get($LOGIN_URI);
	$self->_check_res;

	$self->mech->submit_form(
	    fields => {
		pixiv_id => $pixiv_id,
		pass     => $password,
	    },
	);
	$self->_check_res;
    }
}

sub user_id {
    my ($self) = @_;

    if ( ! $self->mech->get($PROFILE_URI)->is_success ) {
	die "Can't get content: " . $self->res->req->uri;
    }

    $self->mech->content =~ /profile_banner.php\?id=(\d+)/;
    my $user_id = $1;

    return $user_id;
}

sub illust_info {
    my ($self, $illust_id) = @_;

    WebService::Pixiv::Illust->new(
	mech => $self->mech,
	id   => $illust_id,
    );
}

sub find_member_illust {
    my ($self, $user_id) = @_;

    WebService::Pixiv::MemberIllust->new(
	mech => $self->mech,
	id   => $user_id,
	my_user_id => $self->user_id,
    );
}

sub find_bookmark_illust {
    my ($self, $user_id) = @_;

    WebService::Pixiv::BookmarkIllust->new(
	mech => $self->mech,
	id   => $user_id,
	my_user_id => $self->user_id,
    );
}

sub find_bookmark_user {
    my ($self, $user_id) = @_;

    WebService::Pixiv::BookmarkUser->new(
	mech => $self->mech,
	id   => $user_id,
	my_user_id => $self->user_id,
    );
}

sub find_mypixiv {
    my ($self, $user_id) = @_;

    WebService::Pixiv::MyPixiv->new(
	mech => $self->mech,
	id   => $user_id,
	my_user_id => $self->user_id,
    );
}

sub add_bookmark {
    my ($self, $user_id, $restrict) = @_;
    $restrict ||= 0;

    if ( ! $self->mech->get("$MEMBER_URI?id=$user_id")->is_success ) {
	die "Can't get content: " . $self->res->req->uri;
    }

    my $number = 0;
    for my $form ($self->mech->forms) {
	if ($form->action eq '/bookmark_add.php') {
	    last;
	}
	$number++;
    }

    $self->mech->form_number($number)->param('restrict' => $restrict);
    $self->mech->submit;
}

sub search_illust {
    my ($self, @tags) = @_;

    WebService::Pixiv::Search->new(
	mech => $self->mech,
	tags => \@tags,
    );
}

sub _check_res {
    my ($self) = @_;
    if ( ! $self->mech->res->is_success ) {
	die "Can't get content: " . $self->mech->uri;
    }
    sleep $self->delay;
}

1;
__END__

=head1 NAME

WebService::Pixiv -

=head1 SYNOPSIS

  use WebService::Pixiv;

=head1 DESCRIPTION

WebService::Pixiv is

=head1 AUTHOR

memememomo E<lt>memememmomo@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
