package Mojolicious::Plugin::ValidateTiny;
use Mojo::Base 'Mojolicious::Plugin';

use v5.10;
use strict;
use warnings;

use Carp qw/croak/;
 
use Validate::Tiny;
use Mojo::Util qw/camelize/;
use v5.10;

our $VERSION = '0.06';

# TODO check in after_static_dispatch hook that there are params and should be validated
# in after_dispatch hook check that in action validation was called

sub register {
    my ( $self, $app, $conf ) = @_;
    my $log = $app->log;

    # Processing config
    $conf = {
        explicit   => 0,
        autofields => 1,
        exclude    => [],
        %{ $conf || {} } };

    if ( $conf->{autorules} && ref $conf->{autorules} ne 'CODE' ) {
        $conf->{autorules} = 0;
    }

    # Helper do_validation
    $app->helper(
        do_validation => sub {
            my ( $c, $rules, $params ) = @_;
            croak "ValidateTiny: Wrong validatation rules"
                unless ref($rules) ~~ [ 'ARRAY', 'HASH' ];

            $c->stash('is_validate_tiny_called', 1);
            
            $rules = { checks => $rules } if ref $rules eq 'ARRAY';
            $rules->{fields} ||= [];

            # Validate GET+POST parameters by default
            $params ||= { map { $_ => $c->param($_) } $c->param };
            
            # Autofill fields
            if ( $conf->{autofields} ) {
                push @{$rules->{fields}}, keys %$params;
                for ( my $i = 0; $i< @{$rules->{checks}}; $i += 2 ){
                    my $field = $rules->{checks}[$i];
                    next if ref $field eq 'Regexp';
                    push @{$rules->{fields}}, $field;
                }
            }
            
            # Remove fields duplications
            my %h;
            @{$rules->{fields}} = grep { !$h{$_}++ } @{$rules->{fields}};    

            # Check that there is an individual rule for every field
            if ( $conf->{explicit} ) {
                my %h = @{ $rules->{checks} };
                my @fields_wo_rules;

                foreach my $f ( @{ $rules->{fields} } ) {
                    next if $f ~~ $conf->{exclude};
                    push @fields_wo_rules, $f unless exists $h{$f};
                }

                if (@fields_wo_rules) {
                    my $err_msg = 'ValidateTiny: No validation rules for '
                        . join( ', ', map { qq'"$_"' } @fields_wo_rules );
                    
                    my $errors = {};
                    foreach my $f (@fields_wo_rules) {
                        $errors->{$f} = "No validation rules for field \"$f\"";
                    }
                    $c->stash( validate_tiny_errors => $errors);
                    $log->debug($err_msg);
                    return 0;
                }
            }

            # Do validation
            my $result = Validate::Tiny->new( $params, $rules );
            if ( $result->success ) {
                $log->debug('ValidateTiny: Successful');
                return $result->data;
            } else {
                $log->debug( 'ValidateTiny: Failed: ' . join( ', ', keys %{ $result->error } ) );
                $c->stash( validate_tiny_errors => $result->error );
                return;
            }
        } );

    # Helper validator_has_errors
    $app->helper(
        validator_has_errors => sub {
            my $c      = shift;
            my $errors = $c->stash('validate_tiny_errors');

            return 0 if !$errors || !keys %$errors;
            return 1;
        } );

    # Helper validator_errors
    $app->helper(
        validator_errors => sub {
            my ( $c, $name ) = @_;
            my $errors = $c->stash('validate_tiny_errors');

            return $errors unless defined $name;

            if ( $errors && defined $errors->{$name} ) {
                return $errors->{$name};
            }
        } );

    # Helper validator_one_error
    $app->helper(
        validator_any_error => sub {
            my ( $c ) = @_;
            my $errors = $c->stash('validate_tiny_errors');
            
            if ( $errors ) {
                return ( ( values %$errors )[0] );
            }
            
            return;
        } );


    # Print info about actions without validation    
    $app->hook(
        after_dispatch => sub {
            my ($c) = @_;
            my $stash = $c->stash;
            return 1 if $stash->{is_validate_tiny_called};
            
            if ( $stash->{controller} && $stash->{action} ) {
                $log->debug("ValidateTiny: No validation in [$stash->{controller}#$stash->{action}]");    
                return 0;
            }
            
            return 1;
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

=head1 OPTIONS

=head2 C<explicit>

DEFAULT 0

=head2 C<autofields>

DEFAULT 1

=head2 C<exclude>

DEFAULT []

=head1 HELPERS

=head2 C<do_validation>

Validates parameters with provided rules and automatically set errors.

$VALIDATE_RULES - Validate::Tiny rules in next form

    {
        checks  => $CHECKS, # Required
        fields  => [],      # Optional (will check all GET+POST parameters)
        filters => [],      # Optional
    }

You can pass only "checks" array to "do_validation". 
In this case validator will take all GET+POST parameters as "fields"

returns false if validation failed
returns true  if validation succeded

    $self->do_validation($VALIDATE_RULES)
    $self->do_validation($CHECKS);


=head2 C<validator_has_errors>

Check if there are any errors.

    %= if (validator_has_errors) {
        <div class="error">Please, correct the errors below.</div>
    % }

=head2 C<validator_error>

Returns the appropriate error.

    my $errors_hash = $self->validator_error();
    my $username_error = $self->validator_error('username');

    <%= validator_error 'username' %>
    
=head2 C<validator_any_error>
    
Returns any of the existing errors. This method is usefull if you want return only one error.


=head1 SEE ALSO

L<Validate::Tiny>, L<Mojolicious>, L<Mojolicious::Plugin::Validator> 

=cut
