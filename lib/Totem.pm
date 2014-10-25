use v6;

# External
use HTTP::Easy::PSGI;
use URI;

use Totem::Util;

module Totem
{

=begin pod

Runs the Totem webserver at host:port. If host is empty
then it listens on all interfaces

=end pod

	our sub run(Str $host, Int $port)
	{

		# Trap Ctrl-C to properly execute END { } to enable
		# showing of deprecated messages
		#signal(SIGINT).tap({
		#	"Ctrl-C detected".say;
		#	die
		#});

		# Development or panda-installed?
		my $files-dir = 'lib/Totem/files';
		unless "$files-dir/assets/main.js".IO ~~ :e {
			say "Switching to panda-installed totem";
			my @dirs = $*SPEC.splitdir($*EXECUTABLE);
			$files-dir = $*SPEC.catdir(
				@dirs[0..*-3], 
				'languages', 'perl6', 'site', 'lib', 'Totem', 'files'
			);
		}

		# Make sure files contains main.js
		die "main.js is not found in {$files-dir}/assets" 
			unless $*SPEC.catdir($files-dir, 'assets', 'main.js').IO ~~ :e;

		say "Totem is serving files from {$files-dir} at http://$host:$port";
		my $app = sub (%env)
		{
			return [400,['Content-Type' => 'text/plain'],['']] if %env<REQUEST_METHOD> eq '';

			my Str $filename;
			my Str $uri = %env<REQUEST_URI>;

			# Remove the query string part
			$uri ~~ s/ '?' .* $ //;

			# Handle files and routes :)
			if $uri eq '/'
			{
				$filename = 'index.html';
			} 
			else 
			{
				$filename = $uri.substr(1);
			}

			# Get the real file from the local filesystem
			#TODO more robust and secure way of getting files. We could easily be attacked from here
			$filename = $*SPEC.catdir($files-dir, $filename);
			my Str $mime-type = Totem::Util::find-mime-type($filename);
			my Int $status;
			my $contents;
			if ($filename.IO ~~ :e)
			{
				$status = 200;
				$contents = $filename.IO.slurp(:enc('ASCII'));
			} 

			unless ($contents)
			{
				$status = 404;
				$mime-type = 'text/plain';
				$contents = "Not found $uri";	
			}

			[ 
				$status, 
				[ 'Content-Type' => $mime-type ], 
				[ $contents ] 
			];
		}

		my $server = HTTP::Easy::PSGI.new(:host($host), :port($port));
		$server.app($app);
		$server.run;
	}

}

# vim: ft=perl6
