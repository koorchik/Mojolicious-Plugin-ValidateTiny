package Mojolicious::Plugin::ValidateTiny;
use Mojo::Base 'Mojolicious::Plugin';

use Validate::Tiny;

our $VERSION = '0.02';

sub register {
    my ( $self, $app, $conf ) = @_;
    $conf ||= {};

    $app->helper(
        do_validation => sub {
            my ( $self, $rules, $params ) = @_;
            $params ||= $self->req->params->to_hash;

            my $result = Validate::Tiny->new( $params, $rules );
            if ( $result->success ) {
                $self->app->log->debug('ValidateTiny: Successful');
                return $result->data;
            } else {
                $self->app->log->debug('ValidateTiny: Failed: ' . join( ' ,' , keys %{$result->error} ));
                $self->stash( validate_tiny_errors => $result->error );
                return;
            }
        } );

    $app->helper(
        validator_has_errors => sub {
            my $self   = shift;
            my $errors = $self->stash('validate_tiny_errors');

            return 0 if !$errors || !keys %$errors;
            return 1;
        } );

    $app->helper(
        validator_error => sub {
            my ( $self, $name ) = @_;
            my $errors = $self->stash('validate_tiny_errors');

            return $errors unless defined $name;

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

        # Validate $self->param()    
        my $validate_rules = {};
        if ( my $params =  $self->do_validation($validate_rules) ) {
            # all $params are validated and filters are applyed
            ... do you action ...

            # Validate custom data
            my $rules = {...};
            my $data = {...};
            if ( my $data = $self->do_validation($rules, $data) ) {
                
            } else {
                my $errors_hash = $self->validator_error();
            }            
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

    my $errors_hash = $self->validator_error();
    my $username_error = $self->validator_error('username');

    <%= validator_error 'username' %>

    Render the appropriate error.

=head1 SEE ALSO

    L<Validate::Tiny>, L<Mojolicious>, L<Mojolicious::Plugin::Validator> 

=cut
