package Mojolicious::Plugin::ValidateTiny;
use Mojo::Base 'Mojolicious::Plugin';

use Validate::Tiny;

our $VERSION = '0.01';

sub register {
    my ( $self, $app, $conf ) = @_;
    $conf ||= {};

    $app->helper(
        validate => sub {
            my ( $self, $rules, $params ) = @_;
            $params ||= $self->req->params->to_hash;

            my $result = Validate::Tiny->new( $params, $rules );
            if ( $result->success ) {
                return $result->data;
            } else {
                $self->stash( validator_errors => $result->error );
            }
        } );

    $app->helper(
        validator_has_errors => sub {
            my $self   = shift;
            my $errors = $self->stash('validator_errors');

            return 0 if !$errors || !keys %$errors;
            return 1;
        } );

    $app->helper(
        validator_error => sub {
            my ( $self, $name ) = @_;
            my $errors = $self->stash('validator_errors');

            if ( $errors && defined $errors->{$name} ) {
                return $errors->{$name};
            }
        } );
}

1;

=head1 NAME

Mojolicious::Plugin::ValidateTiny - Mojolicious Plugin

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('ValidateTiny');
    
    # Mojolicious::Lite
    plugin 'ValidateTiny';
    
    sub action {
        my $self = shift;
    
        my $validate_rules = {};
        
        if ( my $params =  $self->validate($validate_rules) ) {
            # all $params are validated and filters are applyed
            ... do you action ...
        } else {
            $self->render(status => '403', text => 'FORBIDDEN');  
        }
        
    }
  
    __DATA__
  
    @@ user.html.ep
    %= if (validator_has_errors) {
        <div class="error">Please, correct the errors below.</div>
    % }
    %= form_for 'user' => begin
        <label for="username">Username</label><br />
        <%= input_tag 'username' %><br />
        <%= validator_error 'username' %><br />
  
        <%= submit_button %>
    % end

  
=head1 DESCRIPTION

    L<Mojolicious::Plugin::ValidateTiny> is a L<Validate::Tiny> support in L<Mojolicious>.

=head1 METHODS

    L<Mojolicious::Plugin::ValidateTiny> inherits all methods from
    L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

    Register plugin in L<Mojolicious> application.


=head1 HELPERS

=head2 validate

    $self->validate($validate_rules);

    Validate parameters with provided validator and automatically set errors.

=head2 validator_has_errors

    %= if (validator_has_errors) {
        <div class="error">Please, correct the errors below.</div>
    % }

Check if there are any errors.

=head2 validator_error

    <%= validator_error 'username' %>

    Render the appropriate error.

=head1 SEE ALSO

    L<Validate::Tiny>, L<Mojolicious>, L<Mojolicious::Plugin::Validator> 

=cut
