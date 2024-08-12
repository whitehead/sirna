##################################################
package Log::Log4perl::Logger;
##################################################

use 5.006;
use strict;
use warnings;

use Log::Log4perl::Level;
use Log::Log4perl::Layout;
use Log::Log4perl::Appender;
use Log::Dispatch;
use Carp;

use constant DEBUG => 0;

    # Initialization
our $ROOT_LOGGER;
our $LOGGERS_BY_NAME = {};
our %APPENDER_BY_NAME = ();
our $INITIALIZED;

our $DISPATCHER = Log::Dispatch->new();

our $WATCH_DELAY;
our $FILE_TO_WATCH;
our $LAST_CHECKED_AT;
our $LAST_CHANGED_AT;

__PACKAGE__->reset();

##################################################
sub reset {
##################################################
    $ROOT_LOGGER        = __PACKAGE__->_new("", $DEBUG);
#    $LOGGERS_BY_NAME    = {};  #leave this alone, it's used by 
                                #reset_all_output_methods when the config changes


    #we've got a circular reference thing going on somewhere
    foreach my $appendername (keys %APPENDER_BY_NAME){
        delete $APPENDER_BY_NAME{$appendername}->{appender} 
                if (exists $APPENDER_BY_NAME{$appendername} &&
                    exists $APPENDER_BY_NAME{$appendername}->{appender});
    }
    %APPENDER_BY_NAME   = ();
    $DISPATCHER         = Log::Dispatch->new();
    undef $INITIALIZED;
    Log::Log4perl::Appender::reset();

    #clear out all the existing appenders
    foreach my $logger (values %$LOGGERS_BY_NAME){
        $logger->{appender_names} = ();

	#this next bit deals with an init_and_watch case where a category
	#is deleted from the config file, we need to zero out the existing
	#loggers so ones not in the config file not continue with their old
	#behavior --kg
        next if $logger eq $ROOT_LOGGER;
        $logger->{level} = undef;
        $logger->level();  #set it from the heirarchy
    }
}

##################################################
sub _new {
##################################################
    my($class, $category, $level) = @_;

    print("_new: $class/$category/", defined $level ? $level : "undef",
          "\n") if DEBUG;

    die "usage: __PACKAGE__->_new(category)" unless
        defined $category;
    
    $category  =~ s/::/./g;

       # Have we created it previously?
    if(exists $LOGGERS_BY_NAME->{$category}) {
        print "_new: exists already\n" if DEBUG;
        return $LOGGERS_BY_NAME->{$category};
    }

    my $self  = {
        category  => $category,
        num_appenders => 0,
        additivity    => 1,
        level         => $level,
        layout        => undef,
                };

   bless $self, $class;

   $level ||= $self->level();

        # Save it in global structure
   $LOGGERS_BY_NAME->{$category} = $self;

   $self->set_output_methods;

   return $self;
}

##################################################
sub reset_all_output_methods {
##################################################
    print "reset_all_output_methods: \n" if DEBUG;

    foreach my $loggername ( keys %$LOGGERS_BY_NAME){
        $LOGGERS_BY_NAME->{$loggername}->set_output_methods;
    }
    $ROOT_LOGGER->set_output_methods;
}

##################################################
sub set_output_methods {
# Here's a big performance increase.  Instead of having the logger
# calculate whether to log and whom to log to every time log() is called,
# we calculcate it once when the logger is created, and recalculate
# it if the config information ever changes.
#
##################################################
   my ($self) = @_;
    
   my (@appenders, %seen);

   my ($level) = $self->level();

   print "set_output_methods: $self->{category}/$level\n" if DEBUG;

   #collect the appenders in effect for this category    

   for(my $logger = $self; $logger; $logger = parent_logger($logger)) {

        foreach my $appender_name (@{$logger->{appender_names}}){

                #only one message per appender, (configurable)
            next if $seen{$appender_name} ++ && 
                    $Log::Log4perl::one_message_per_appender;

            push (@appenders,     
                   [$appender_name,
                    $APPENDER_BY_NAME{$appender_name},
                   ]
            );
        }
        last unless $logger->{additivity};
    }

        #make a no-op coderef for inactive levels
    my $noop = generate_noop_coderef();

       #make a coderef
    my $coderef = (! @appenders ? $noop : &generate_coderef(\@appenders)); 

    my %priority = %Log::Log4perl::Level::PRIORITY; #convenience and cvs

   # changed to >= from <= as level ints were reversed
    foreach my $levelname (keys %priority){
        if (Log::Log4perl::Level::isGreaterOrEqual($level,
						   $priority{$levelname}
						   )) {
            print "  ($priority{$levelname} <= $level)\n"
                  if DEBUG;
            $self->{$levelname} = $coderef;
        }else{
            print "  ($priority{$levelname} > $level)\n" if DEBUG;
            $self->{$levelname} = $noop;
        }

        print("  Setting [$self] $self->{category}.$levelname to ",
              ($self->{$levelname} == $noop ? "NOOP" : 
              ("Coderef [$coderef]: " . scalar @appenders . " appenders")), 
              "\n") if DEBUG;
    }
}

##################################################
sub generate_coderef {
##################################################
    my $appenders = shift;
                    
    print "generate_coderef: ", scalar @$appenders, 
          " appenders\n" if DEBUG;

    my $coderef = '';
    my $watch_delay_code = '';

    # Doing this with eval strings to sacrifice init/reload time
    # for runtime efficiency, so the conditional won't be included
    # if it's not needed

    if (defined $WATCH_DELAY) {
        $watch_delay_code = generate_watch_code();
    }

    my $code = <<EOL;
    \$coderef = sub {
      my (\$logger)  = shift;
      my (\$level)   = pop;
      my \$message;
      my \$appenders_fired = 0;
      
      # Evaluate all parameters that need to evaluated. Two kinds:
      #
      # (1) It's a hash like { filter => "filtername",
      #                        value  => "value" }
      #     => filtername(value)
      #
      # (2) It's a code ref
      #     => coderef()
      #

      \$message   = [map { ref \$_ eq "HASH" && 
                           exists \$_->{filter} && 
                           ref \$_->{filter} eq 'CODE' ?
                               \$_->{filter}->(\$_->{value}) :
                           ref \$_ eq "CODE" ?
                               \$_->() : \$_ 
                          } \@_];                  
      
      print("coderef: \$logger->{category}\n") if DEBUG;

      $watch_delay_code;  #note interpolation here
      
      foreach my \$a (\@\$appenders) {   #note the closure here
          my (\$appender_name, \$appender) = \@\$a;

          print("  Sending message '<\$message>' (\$level) " .
                "to \$appender_name\n") if DEBUG;
                
          \$appender->log(
              #these get passed through to Log::Dispatch
              { name    => \$appender_name,
                level   => \$Log::Log4perl::Level::L4P_TO_LD{\$level},   
                message => \$message,
              },
              #these we need
              \$logger->{category},
              \$level,
          ) and \$appenders_fired++;
              # Only counting it if it returns a true value. Otherwise
              # the appender threshold might have suppressed it after all.
    
      } #end foreach appenders
    
      return \$appenders_fired;

    }; #end coderef

EOL

    eval $code or die "$@";

    return $coderef;
}

##################################################
sub generate_noop_coderef {
##################################################
    my $coderef = '';
    my $watch_delay_code = '';

    if (defined $WATCH_DELAY) {
        $watch_delay_code = generate_watch_code();
        $watch_delay_code = <<EOL;
        my (\$logger)  = shift;
        my (\$level)   = pop;
        $watch_delay_code
EOL
    }

    my $code = <<EOL;
    \$coderef = sub {
        print("noop: \n") if DEBUG;
        $watch_delay_code
        return undef;
     };
EOL

    eval $code or die "$@";

    return $coderef;
}


##################################################
sub generate_watch_code {
##################################################
    print "generate_watch_code:\n" if DEBUG;

    return <<'EOL';
        print "exe_watch_code:\n" if DEBUG;
                       
        # more closures here
        if ( ($LAST_CHECKED_AT + $WATCH_DELAY) < time()){
        
             $LAST_CHECKED_AT = time();

             print "  Checking $FILE_TO_WATCH for changes ...\n" if DEBUG;
        
             if ($LAST_CHANGED_AT < (stat($FILE_TO_WATCH))[9] ){
                       
                 $LAST_CHANGED_AT = (stat(_))[9];
                       
                 print "  Config file has been modified\n" if DEBUG;
                       
                 Log::Log4perl->init_and_watch($FILE_TO_WATCH, $WATCH_DELAY);
                       
                 my $methodname = lc($level);
                 $logger->$methodname(@_); # send the message
                                                 # to the new configuration
                 return;        #and return, we're done with this incarnation
             }
        }
EOL
}

##################################################
sub parent_string {
##################################################
    my($string) = @_;

    if($string eq "") {
        return undef; # root doesn't have a parent.
    }

    my @components = split /\./, $string;
    
    if(@components == 1) {
        return "";
    }

    pop @components;

    return join('.', @components);
}

##################################################
sub level {
##################################################
    my($self, $level, $dont_reset_all) = @_;

        # 'Set' function
    if(defined $level) {
        croak "invalid level '$level'" 
                unless Log::Log4perl::Level::is_valid($level);
        $self->{level} = $level;   

        &reset_all_output_methods
            unless $dont_reset_all;  #keep us from getting overworked 
                                     #if it's the config file calling us 

        return $level;
    }

        # 'Get' function
    if(defined $self->{level}) {
        return $self->{level};
    }

    for(my $logger = $self; $logger; $logger = parent_logger($logger)) {

        # Does the current logger have the level defined?

        if($logger->{category} eq "") {
            # It's the root logger
            return $ROOT_LOGGER->{level};
        }
            
        if(defined $LOGGERS_BY_NAME->{$logger->{category}}->{level}) {
            return $LOGGERS_BY_NAME->{$logger->{category}}->{level};
        }
    }

    # We should never get here because at least the root logger should
    # have a level defined
    die "We should never get here.";
}

##################################################
sub parent_logger {
# Get the parent of the current logger or undef
##################################################
    my($logger) = @_;

        # Is it the root logger?
    if($logger->{category} eq "") {
        # Root has no parent
        return undef;
    }

        # Go to the next defined (!) parent
    my $parent_class = parent_string($logger->{category});

    while($parent_class ne "" and
          ! exists $LOGGERS_BY_NAME->{$parent_class}) {
        $parent_class = parent_string($parent_class);
        $logger =  $LOGGERS_BY_NAME->{$parent_class};
    }

    if($parent_class eq "") {
        $logger = $ROOT_LOGGER;
    } else {
        $logger = $LOGGERS_BY_NAME->{$parent_class};
    }

    return $logger;
}

##################################################
sub get_root_logger {
##################################################
    my($class) = @_;
    return $ROOT_LOGGER;    
}

##################################################
sub additivity {
##################################################
    my($self, $onoff) = @_;

    if(defined $onoff) {
        $self->{additivity} = $onoff;
    }

    return $self->{additivity};
}

##################################################
sub get_logger {
##################################################
    my($class, $category) = @_;

    unless(defined $ROOT_LOGGER) {
        die "Internal error: Root Logger not initialized.";
    }

    return $ROOT_LOGGER if $category eq "";

    my $logger = $class->_new($category);
    return $logger;
}

##################################################
sub add_appender {
##################################################
    my($self, $appender, $dont_reset_all) = @_;

    my $not_to_dispatcher = 0;

        # We take this as an indicator that we're initialized.
    $INITIALIZED = 1;

    my $appender_name = $appender->name();

    $self->{num_appenders}++;  #should this be inside the unless?

    unless (grep{$_ eq $appender_name} @{$self->{appender_names}}){
        $self->{appender_names} = [sort @{$self->{appender_names}}, 
                                        $appender_name];
    }

    if ($APPENDER_BY_NAME{$appender_name}) {
        $not_to_dispatcher = 1;
    }else{
        $APPENDER_BY_NAME{$appender_name} = $appender;
    }

    &reset_all_output_methods
                unless $dont_reset_all;  # keep us from getting overworked
                                         # if it's  the config file calling us


    #$self->{dispatcher}->add($appender) unless $not_to_dispatcher;    
    $DISPATCHER->add($appender) unless $not_to_dispatcher;    
        # while we want to track the names of
        # all the appenders in a category, we only
        # want to add it to log_dispatch *once*
}

##################################################
sub has_appenders {
##################################################
    my($self) = @_;

    return $self->{num_appenders};
}

##################################################
sub init_watch {
##################################################
    $WATCH_DELAY = shift;

    $LAST_CHECKED_AT = $LAST_CHANGED_AT = time();
}

##################################################
sub set_file_to_watch {
##################################################
    $FILE_TO_WATCH = shift;
}

##################################################
sub log {
# external api
##################################################
    my ($self, $priority, @messages) = @_;

    confess("log: No priority given!") unless defined($priority);

       # Just in case of 'init_and_watch' -- see Changes 0.21
    $_[0] = $LOGGERS_BY_NAME->{$_[0]->{category}} if defined $LAST_CHECKED_AT;

    init_warn() unless $INITIALIZED;

    croak "priority $priority isn't numeric" if ($priority =~ /\D/);

    my $which = Log::Log4perl::Level::to_level($priority);

    $self->{$which}->($self, @messages, 
                    Log::Log4perl::Level::to_level($priority));
}

######################################################################
#
# create_custom_level 
# creates a custom level
# in theory, could be used to create the default ones

sub create_custom_level {
  my $level = shift || die("create_custom_level: forgot to pass in a level string!");
  my $after = shift || die("create_custom_level: forgot to pass in a level after which to place the new level!");
  my $syslog_equiv = shift; # can be undef

  ## only let users create custom levels before initialization

  die("create_custom_level must be called before init or first get_logger() call") if ($INITIALIZED);

  my %PRIORITY = %Log::Log4perl::Level::PRIORITY; #convenience

  die("create_custom_level: no such level \"$after\"! Use one of: ", join(", ", sort keys %PRIORITY))
    unless $PRIORITY{$after};

  # figure out new int value by AFTER + (AFTER+ 1) / 2

  my $next_prio = Log::Log4perl::Level::get_lower_level($PRIORITY{$after}, 1);
  my $cust_prio = int(($PRIORITY{$after} + $next_prio) / 2);

#   CORE::warn("Creating prio $cust_prio between $PRIORITY{$after} and $next_prio");

  die(qq{create_custom_level: Calculated level of $cust_prio already exists!
      This should only happen if you've made some insane number of custom
      levels (like 15 one after another)
      You can usually fix this by re-arranging your code from:
      create_custom_level("cust1", X);
      create_custom_level("cust2", X);
      create_custom_level("cust3", X);
      create_custom_level("cust4", X);
      create_custom_level("cust5", X);
      into:
      create_custom_level("cust3", X);
      create_custom_level("cust5", X);
      create_custom_level("cust4", 4);
      create_custom_level("cust2", cust3);
      create_custom_level("cust1", cust2);
   }) if (${Log::Log4perl::Level::LEVELS{$cust_prio}});

  Log::Log4perl::Level::add_priority($level, $cust_prio, $syslog_equiv);

  print("Adding prio $level at $cust_prio\n") if DEBUG;

  # get $LEVEL into namespace of Log::Log4perl::Logger to 
  # create $logger->foo nd $logger->is_foo
  my $name = "Log::Log4perl::Logger::";
  my $key = $level;

  no strict qw(refs);
  # be sure to use ${Log...} as CVS adds log entries for Log
  *{"$name$key"} = \${Log::Log4perl::Level::PRIORITY{$level}};

  # now, stick it in the caller's namespace
  $name = caller(0) . "::";
  *{"$name$key"} = \${Log::Log4perl::Level::PRIORITY{$level}};
  use strict qw(refs);

  create_log_level_methods($level);

  return 0;

}

########################################
#
# if we were hackin' lisp (or scheme), we'd be returning some lambda
# expressions. But we aren't. :) So we'll just create some strings and
# eval them.
sub create_log_level_methods {
  my $level = shift || die("create_log_level_methods: forgot to pass in a level string!");
  my $lclevel = lc($level);
  my $levelint = uc($level) . "_INT";

  no strict qw(refs);

  # This is a bit better way to create code on the fly than eval'ing strings.
  # -erik

  *{__PACKAGE__ . "::$lclevel"} = sub {
        print "$lclevel: ($_[0]->{category}/$_[0]->{level}) [@_]\n" if DEBUG;
        init_warn() unless $INITIALIZED;
        $_[0]->{$level}->(@_, $level);
     };

  *{__PACKAGE__ . "::is_$lclevel"} = sub { 
    return Log::Log4perl::Level::isGreaterOrEqual($_[0]->level(),
						  $$level
						  ); 
  };
  
  use strict qw(refs);

  return 0;

}

#now lets autogenerate the logger subs based on the defined priorities
foreach my $level (keys %Log::Log4perl::Level::PRIORITY){
  create_log_level_methods($level);
}

##################################################
#expected args are $logger, $msg, $levelname

#sub fatal {
#   print "fatal: ($_[0]->{category}/$_[0]->{level}) [@_]\n" if DEBUG;
#   init_warn() unless $INITIALIZED;
#   $_[0]->{FATAL}(@_, 'FATAL');
#}
#
#sub error {
#   print "error: ($_[0]->{category}/$_[0]->{level}) [@_]\n" if DEBUG;
#   init_warn() unless $INITIALIZED;
#   $_[0]->{ERROR}(@_, 'ERROR');
#}
#
#sub warn {
#   print "warn: ($_[0]->{category}/$_[0]->{level}) [@_]\n" if DEBUG;
#   init_warn() unless $INITIALIZED;
#   $_[0]->{WARN} (@_, 'WARN' );
#}
#
#sub info {
#   print "info: ($_[0]->{category}/$_[0]->{level}) [@_]\n" if DEBUG;
#   init_warn() unless $INITIALIZED;
#   $_[0]->{INFO} (@_, 'INFO' );
#}
#
#sub debug {
#   print "debug: ($_[0]->{category}/$_[0]->{level}) [@_]\n" if DEBUG;
#   init_warn() unless $INITIALIZED;
#   $_[0]->{DEBUG}(@_, 'DEBUG');
#}

#sub is_debug { return $_[0]->level() >= $DEBUG; }
#sub is_info  { return $_[0]->level() >= $INFO; }
#sub is_warn  { return $_[0]->level() >= $WARN; }
#sub is_error { return $_[0]->level() >= $ERROR; }
#sub is_fatal { return $_[0]->level() >= $FATAL; }
sub init_warn {
    CORE::warn "Log4perl: Seems like no initialization happened. Forgot to call init()?\n";
    # Only tell this once;
    $INITIALIZED = 1;
              }

##################################################
# call me from a sub-func to spew the sub-func's caller
sub callerline {
  # the below could all be just:
  # my ($pack, $file, $line) = caller(2);
  # but if we every bury this further, it'll break. So we do this
  # little trick stolen and paraphrased from Carp/Heavy.pm

  my $i = 0;
  my (undef, $localfile, undef) = caller($i++);
  my ($pack, $file, $line);
  do {
    ($pack, $file, $line) = caller($i++);
  } while ($file && $file eq $localfile);

  # now, create the return message
  my $mess = " at $file line $line";
  # Someday, we'll use Threads. Really.
  if (defined &Thread::tid) {
    my $tid = Thread->self->tid;
    $mess .= " thread $tid" if $tid;
  }
  return (@_, $mess, "\n");
}

sub and_warn {
  my $self = shift;
  my $msg = join("", @_[0 .. $#_]);
  chomp $msg;
  CORE::warn(callerline($msg));
}

sub and_die {
  my $self = shift;
  my $msg = join("", @_[0 .. $#_]);
  chomp $msg;
  die(callerline($msg));
}

##################################################

sub logwarn {
  my $self = shift;
  if ($self->is_warn()) {
        # Since we're one caller level off now, compensate for that.
    $Log::Log4perl::caller_depth++;
    $self->warn(@_);
    $Log::Log4perl::caller_depth--;
    $self->and_warn(@_);
  }
}

sub logdie {
  my $self = shift;
  if ($self->is_fatal()) {
        # Since we're one caller level off now, compensate for that.
    $Log::Log4perl::caller_depth++;
    $self->fatal(@_);
    $Log::Log4perl::caller_depth--;
  }
  # no matter what, we die... 'cuz logdie wants you to die.
  $self->and_die(@_);
}

##################################################

# for die and warn, carp long/shortmess return line #s and the like
sub noop {
  return @_;
}

##################################################

# clucks and carps are WARN level
sub logcluck {
  my $self = shift;
  if ($self->is_warn()) {
    my $message = Carp::longmess(@_);
    foreach (split(/\n/, $message)) {
      $self->warn("$_\n");
    }
    CORE::warn(noop($message));
  }
}

sub logcarp {
  my $self = shift;
  if ($self->is_warn()) {
    my $message = Carp::shortmess(@_);
    foreach (split(/\n/, $message)) {
      $self->warn("$_\n");
    }
    CORE::warn(noop($message));
  }
} 

# croaks and confess are FATAL level
sub logcroak {
  my $self = shift;
  my $message = Carp::shortmess(@_);
  if ($self->is_fatal()) {
    foreach (split(/\n/, $message)) {
      $self->fatal("$_\n");
    }
  }
  # again, we die no matter what
  die(noop($message));
}

sub logconfess {
  my $self = shift;
  my $message = Carp::longmess(@_);
  if ($self->is_fatal()) {
    foreach (split(/\n/, $message)) {
      $self->fatal("$_\n");
    }
  }
  # again, we die no matter what
  die(noop($message));
}

##################################################
# 
# in case people prefer to use error for warning

sub error_warn {
  my $self = shift;
  if ($self->is_error()) {
    $self->error(@_);
    $self->and_warn(@_);
  }
}

sub error_die {
  my $self = shift;
  if ($self->is_error()) {
    $self->error(@_);
  }
  $self->and_die(@_);
}

sub more_logging {
  my ($self) = shift;
  return $self->dec_level(@_);
}

sub inc_level {
    my ($self, $delta) = @_;

    $delta ||= 1;

    $self->level(Log::Log4perl::Level::get_higher_level($self->level(), $delta));

    $self->set_output_methods;

}

sub less_logging {
  my ($self) = shift;
  return $self->inc_level(@_);
}

sub dec_level {
    my ($self, $delta) = @_;

    $delta ||= 1;

    $self->level(Log::Log4perl::Level::get_lower_level($self->level(), $delta));

    $self->set_output_methods;
}

##################################################

1;

__END__

=head1 NAME

Log::Log4perl::Logger - Main Logger Class

=head1 SYNOPSIS

    # It's not here

=head1 DESCRIPTION

While everything that makes Log4perl tick is implemented here,
please refer to L<Log::Log4perl> for documentation.

=head1 SEE ALSO

=head1 AUTHOR

    Mike Schilli, <log4perl@perlmeister.com>
    Kevin Goess, <cpan@goess.org>

=cut
