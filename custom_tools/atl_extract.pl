#!/usr/bin/perl
#
# atl_extract.pl
# ATL archive extractor for "Cool Cool Toon".
#
# Written by Derek Pascarella (ateam)

use strict;
use utf8;
use JSON;
use HTTP::Tiny;
use Spreadsheet::WriteExcel;
use Encode qw(decode encode);
use String::HexConvert ':all';
use URI::Encode qw(uri_encode uri_decode);

my $file_input = $ARGV[0];
(my $file_input_basename = $file_input) =~ s{^.*/|\.[^.]+$}{}g;
my $folder_output = $ARGV[1];
my $string_count = hex(&endian_swap(&read_bytes_at_offset($file_input, 4, 40))) - 1;

my $workbook = Spreadsheet::WriteExcel->new($folder_output . $file_input_basename . ".xls");
my $worksheet = $workbook->add_worksheet();
my $header_bg_color = $workbook->set_custom_color(40, 191, 191, 191);

my $header_format = $workbook->add_format();
$header_format->set_bold();
$header_format->set_border();
$header_format->set_bg_color(40);

my $cell_format = $workbook->add_format();
$cell_format->set_border();
$cell_format->set_align('left');
$cell_format->set_text_wrap();

$worksheet->set_column('B:B', 15);
$worksheet->set_column('C:C', 60);
$worksheet->set_column('D:D', 60);
$worksheet->set_column('E:E', 50);
$worksheet->set_column('F:F', 50);

$worksheet->write(0, 0, "String #", $header_format);
$worksheet->write(0, 1, "Format", $header_format);
$worksheet->write(0, 2, "Japanese Text", $header_format);
$worksheet->write(0, 3, "English Translation", $header_format);
$worksheet->write(0, 4, "Notes", $header_format);
$worksheet->write(0, 5, "Machine Translation", $header_format);

print "------------------------------------\n";

for(my $i = 0; $i < $string_count * 4; $i += 4)
{
	my $format;
	my $pointer_location = 68 + $i;
	my $pointer_value = hex(&endian_swap(&read_bytes_at_offset($file_input, 4, $pointer_location)));

	print "dialog instance " . (($i / 4) + 1) . " pointer value = $pointer_value\n";

	$worksheet->write((($i / 4) + 1), 0, (($i / 4) + 1), $cell_format);
	$worksheet->write((($i / 4) + 1), 3, "", $cell_format);
	$worksheet->write((($i / 4) + 1), 4, "", $cell_format);
	$worksheet->write((($i / 4) + 1), 5, "", $cell_format);

	if($i < $string_count * 4)
	{
		my $chunk_size = hex(&endian_swap(&read_bytes_at_offset($file_input, 4, $pointer_value)));
		my $chunk_size_with_header = $chunk_size + 4;
		my $extracted_chunk = &read_bytes_at_offset($file_input, $chunk_size_with_header, $pointer_value);

		while($chunk_size_with_header % 4 != 0)
		{
			$chunk_size_with_header ++;
			$extracted_chunk .= "00";
		}

		my $extracted_string_chunk = &read_bytes_at_offset($file_input, $chunk_size, $pointer_value + 4);
		
		# Insert "[NEW DIALOG BOX]" in between multi-entries.
		$extracted_string_chunk =~ s/feff00/0a5b4e4557204449414c4f4720424f585d0a/g;

		# Remove tile-width control codes from Neo Geo Pocket text.
		if($file_input =~ /NGP/)
		{
			$extracted_string_chunk =~ s/ff23\w{2}//g;
		}

		# Put pre-existing control codes within brackets for character-select text.
		if($file_input =~ /M_MCHAR/)
		{
			my @control_code_matches = ($extracted_string_chunk =~ /ff4100\w{10}/g);

			foreach(@control_code_matches)
			{
				my $control_code_hex = ascii_to_hex("[" . $_. "]");
				$extracted_string_chunk =~ s/$_/$control_code_hex/g;
			}
		}

		# Put pre-existing control codes within brackets for flitz menu text.
		if($file_input =~ /FLZ_MENU/)
		{
			my @control_code_matches = ($extracted_string_chunk =~ /ff4100\w{8}/g);

			foreach(@control_code_matches)
			{
				my $control_code_hex = ascii_to_hex("[" . $_. "]");
				$extracted_string_chunk =~ s/$_/$control_code_hex/g;
			}

			@control_code_matches = ($extracted_string_chunk =~ /ff29fffe/g);

			foreach(@control_code_matches)
			{
				my $control_code_hex = ascii_to_hex("[" . $_. "]");
				$extracted_string_chunk =~ s/$_/$control_code_hex/g;
			}
		}

		# Put pre-existing control codes within brackets for store text.
		if($file_input =~ /SY_YRMSG/ || $file_input =~ /YUSAMES/)
		{
			my @control_code_matches = ($extracted_string_chunk =~ /ff2[012345679]\w{2}/g);

			foreach(@control_code_matches)
			{
				my $control_code_hex = ascii_to_hex("[" . $_. "]");
				$extracted_string_chunk =~ s/$_/$control_code_hex/g;
			}
		}

		my $extracted_string_bytes;
		my @extracted_string_array = ($extracted_string_chunk =~ m/../g);

		foreach(@extracted_string_array)
		{
			next if /00/;

			if($_ eq "fd")
			{
				$_ = "0a";
			}
			elsif($_ eq "fe")
			{
				$_ = "";
				$format = "PRESS_A";
			}

			$extracted_string_bytes .= $_;
		}

		if($extracted_string_bytes =~ /ff2882cd82a2ff280182a282a282a6ff28ff/)
		{
			$extracted_string_bytes =~ s/ff2882cd82a2ff280182a282a282a6ff28ff//g;

			if($format ne "")
			{
				$format .= "\nYES_NO_V1";
			}
			else
			{
				$format = "YES_NO_V1";
			}
		}

		if($extracted_string_bytes =~ /ff2882a482f1ff288182e282beff28ff/)
		{
			$extracted_string_bytes =~ s/ff2882a482f1ff288182e282beff28ff//g;

			if($format ne "")
			{
				$format .= "\nYES_NO_V2";
			}
			else
			{
				$format = "YES_NO_V2";
			}
		}

		if($extracted_string_bytes =~ /ff288082a482f1ff280182e282beff28ff/)
		{
			$extracted_string_bytes =~ s/ff288082a482f1ff280182e282beff28ff//g;

			if($format ne "")
			{
				$format .= "\nYES_NO_V3";
			}
			else
			{
				$format = "YES_NO_V3";
			}
		}

		if($extracted_string_bytes =~ /ff2882a482f1ff280182e282beff28ff/)
		{
			$extracted_string_bytes =~ s/ff2882a482f1ff280182e282beff28ff//g;

			if($format ne "")
			{
				$format .= "\nYES_NO_V4";
			}
			else
			{
				$format = "YES_NO_V4";
			}
		}

		if($format eq "")
		{
			$format = "NONE";
		}

		my $extracted_string;

		&write_bytes("temp.bin", $extracted_string_bytes);

		open(FH, '<', "temp.bin") or die $!;

		while(<FH>)
		{
			$extracted_string .= Encode::encode("utf-8", Encode::decode("shiftjis", $_));
		}

		close(FH);

		unlink("temp.bin");

		print "chunk size stored = $chunk_size / with size header = $chunk_size_with_header\n";
		#print "chunk: $extracted_chunk\n";
		#print "string chunk: $extracted_string_chunk\n";
		#print "string bytes: $extracted_string_bytes\n";
		#print "string:\n$extracted_string\n";
		print "$extracted_string\n";

		my $japanese_text = Encode::decode("utf-8", $extracted_string);
		$japanese_text =~ s/\r\n//g;
		$japanese_text =~ s/\r//g;
		$japanese_text =~ s/\n//g;
		my $http = HTTP::Tiny->new;
		my $post_data = uri_encode("auth_key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX&target_lang=EN-US&source_lang=JA&text=" . $japanese_text);
		my $response = $http->get("https://api-free.deepl.com/v2/translate?" . $post_data);
		my $english_translation = decode_json($response->{'content'})->{'translations'}->[0]->{'text'};
		
		print "$english_translation\n";

		$worksheet->write((($i / 4) + 1), 5, $english_translation, $cell_format);
		$worksheet->write((($i / 4) + 1), 1, $format, $cell_format);
		$worksheet->write_utf16be_string((($i / 4) + 1), 2, Encode::encode("utf-16", Encode::decode("utf-8", $extracted_string)), $cell_format);
	}

	print "------------------------------------\n";
}

$workbook->close();

# Subroutine to swap between big/little endian by reversing order of bytes from specified hexadecimal
# data.
#
# 1st parameter - Hexadecimal representation of data.
sub endian_swap
{
	(my $hex_data = $_[0]) =~ s/\s+//g;
	my @hex_data_array = ($hex_data =~ m/../g);

	return join("", reverse(@hex_data_array));
}

# Subroutine to read a specified number of bytes, starting at a specific offset (in decimal format), of
# a specified file, returning hexadecimal representation of data.
#
# 1st parameter - Full path of file to read.
# 2nd parameter - Number of bytes to read.
# 3rd parameter - Offset at which to read.
sub read_bytes_at_offset
{
	my $file_to_read = $_[0];
	my $bytes_to_read = $_[1];
	my $read_offset = $_[2];

	open my $filehandle, '<:raw', "$file_to_read" or die $!;
	seek $filehandle, $read_offset, 0;
	read $filehandle, my $bytes, $bytes_to_read;
	close $filehandle;
	
	return unpack 'H*', $bytes;
}

# Subroutine to write a sequence of hexadecimal values to a specified file.
#
# 1st parameter - Full path of file to write.
# 2nd parameter - Hexadecimal representation of data to be written to file.
sub write_bytes
{
	my $output_file = $_[0];
	(my $hex_data = $_[1]) =~ s/\s+//g;
	my @hex_data_array = split(//, $hex_data);

	open my $filehandle, '>', $output_file or die $!;
	binmode $filehandle;

	for(my $i = 0; $i < @hex_data_array; $i += 2)
	{
		my($high, $low) = @hex_data_array[$i, $i + 1];
		print $filehandle pack "H*", $high . $low;
	}

	close $filehandle;
}
