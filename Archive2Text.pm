package Archive2Text;

use strict;
use warnings;
use Archive::Tar;
use Encode qw(decode encode);
use File::Path qw(make_path);
use File::Basename qw(dirname);
use File::Find;
use utf8;
use Exporter 'import';

our @EXPORT_OK = qw(to_text from_text);

sub to_text {
  my ($input, $output_filename, $redactor, $type) = @_;
  open(my $output, '>', $output_filename) or die "Could not open file '$output_filename': $!";
  binmode($output, ":utf8");

  if ($type eq 'directory') {
    process_directory($input, $output, $redactor);
  } elsif ($type eq 'tar') {
    process_tar($input, $output, $redactor);
  }

  close($output);
}


sub process_directory {
  my ($dir, $output, $redactor) = @_;

  find(
       sub {
	 return if -d $_;
	 my $filename = $File::Find::name;
	 open(my $file, '<', $filename) or die "Could not open file '$filename': $!";
	 binmode($file, ":utf8");
	 my $content = do { local $/; <$file> };
	 close($file);

	 $content = $redactor->($filename, $content) if $redactor;

	 print $output "--- START FILE: $filename ---\n";
	 print $output $content;
	 print $output "\n--- END FILE: $filename ---\n\n";
       },
       $dir
      );
}

sub process_tar {
  my ($tar_filename, $output, $redactor) = @_;

  my $tar = Archive::Tar->new;
  $tar->read($tar_filename);

  foreach my $file ($tar->get_files) {
    if ($file->is_file) {
      my $content = decode('utf8', $file->get_content, Encode::FB_DEFAULT);
      my $filename = $file->name;

      $content = $redactor->($filename, $content) if $redactor;

      print $output "--- START FILE: $filename ---\n";
      print $output $content;
      print $output "\n--- END FILE: $filename ---\n\n";
    }
  }
}

# sub from_text {
#   my ($input_filename, $output, $is_tar, $type) = @_;

#   open(my $input, '<', $input_filename) or die "Could not open file '$input_filename': $!";
#   binmode($input, ":utf8");

#   my $tar = Archive::Tar->new if $is_tar;
#   my $current_file;
#   my $current_content = '';

#   while (my $line = <$input>) {
#     if ($line =~ /^--- START FILE: (.+) ---$/) {
#       if ($current_file) {
# 	write_output($current_file, $current_content, $output, $is_tar, $tar);
# 	$current_content = '';
#       }
#       $current_file = $1;
#     } elsif ($line =~ /^--- END FILE: .+ ---$/) {
#       write_output($current_file, $current_content, $output, $is_tar, $tar);
#       $current_content = '';
#       $current_file = undef;
#     } else {
#       $current_content .= $line;
#     }
#   }

#   close($input);

#   if ($is_tar) {
#     $tar->write($output);
#   }
# }

# sub write_output {
#   my ($filename, $content, $output, $is_tar, $tar) = @_;

#   if ($is_tar) {
#     $tar->add_data($filename, encode('utf8', $content));
#   } else {
#     my $full_path = "$output/$filename";
#     my $dir = dirname($full_path);
#     make_path($dir) unless -d $dir;
#     open(my $file, '>', $full_path) or die "Could not open file '$full_path': $!";
#     binmode($file, ":utf8");
#     print $file $content;
#     close($file);
#   }
# }

1;
