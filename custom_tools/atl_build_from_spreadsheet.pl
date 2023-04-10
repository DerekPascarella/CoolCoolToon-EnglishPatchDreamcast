#!/usr/bin/perl
#
# atl_build_from_spreadsheet.pl
# ATL archive builder for "Cool Cool Toon".
#
# Written by Derek Pascarella (ateam)

# Include necessary modules.
use utf8;
use strict;
use HTML::Entities;
use String::HexConvert ':all';
use Spreadsheet::Read qw(ReadData);

# Initialize/declare initial variables.
my $file_input = $ARGV[0];
(my $file_input_basename = $file_input) =~ s{^.*/|\.[^.]+$}{}g;
my $folder_output = "/mnt/z/dc/gdi/new/cool_cool_toon/custom_tools/ATL_REBUILT/";
my $file_output = $folder_output;
my $folder_source = "/mnt/z/dc/gdi/new/cool_cool_toon/custom_tools/MBIN_EXTRACTED_ATL/";
my $file_source = $folder_source;
my @word_lengths = ();
my @word_hex = ();
my @string_hex = ();
my @line_length = ();
my $line_count;
my $english_text_hex;
my $processing_after_dialog_break = 0;
my $characters_variable_width_lowercase = "fijl";
my $characters_variable_width_uppercase = "IJR";
my %sjis_character_map = &generate_character_map_hash("sjis_char_map.txt");

# Read and store spreadsheet.
my $spreadsheet = ReadData($file_input);
my @spreadsheet_rows = Spreadsheet::Read::rows($spreadsheet->[1]);

# Status message.
print "Processing script file \"$file_input_basename\" (" . scalar(@spreadsheet_rows) . " rows)...\n----\n";

# Iterate through each row of spreadsheet, storing English text from 4th row in "english_replacements" hash.
for(my $i = 1; $i < scalar(@spreadsheet_rows); $i ++)
{
	# Reset variables for new dialog instance.
	$english_text_hex = "";
	$line_count = 1;

	foreach(@line_length)
	{
		$_ = 0;
	}

	# Store data from current spreadsheet row.
	my $string_number = int($spreadsheet_rows[$i][0]);
	my $dialog_format = $spreadsheet_rows[$i][1];
	my $english_text_raw = decode_entities($spreadsheet_rows[$i][3]);
	my $japanese_text = decode_entities($spreadsheet_rows[$i][2]);

	# added 2022-11-23, believe need to convert these before removing non-ascii/non-printable
	$english_text_raw =~ s/…/\.\.\./g;
	$english_text_raw =~ s/’/'/g;
	$english_text_raw =~ s/”/"/g;
	$english_text_raw =~ s/“/"/g;

	# Clean English text.
	$english_text_raw =~ s/[\r\n]+/ /g;
	$english_text_raw =~ s/[\r]+/ /g;
	$english_text_raw =~ s/[\n]+/ /g;
	$english_text_raw =~ s/\P{IsPrint}//g;
	$english_text_raw =~ s/[^[:ascii:]]+//g;
	$english_text_raw =~ s/\b(all right)\b/alright/g;
	$english_text_raw =~ s/\b(All right)\b/Alright/g;
	$english_text_raw =~ s/\b(ALL RIGHT)\b/ALRIGHT/g;
	$english_text_raw =~ s/\[NEW DIALOG BOX\]/ \[NEW-DIALOG-BOX\] /g;
	$english_text_raw =~ s/\[NL\]/ \[NL\] /g;
	$english_text_raw =~ s/\[ff2400\]/ \[ff2400\] /g;
	$english_text_raw =~ s/\[ff2428\]/ \[ff2428\] /g;
	$english_text_raw =~ s/\[ff2900\]/ \[ff2900\] /g;
	$english_text_raw =~ s/\[ff2901\]/ \[ff2901\] /g;
	$english_text_raw =~ s/\[ff2902\]/ \[ff2902\] /g;
	$english_text_raw =~ s/\[ff2903\]/ \[ff2903\] /g;
	$english_text_raw =~ s/\[ff29ff\]/ \[ff29ff\] /g;
	$english_text_raw =~ s/ +/ /;
	$english_text_raw =~ s/\s+/ /g;
	$english_text_raw =~ s/’/'/g;
	$english_text_raw =~ s/”/"/g;
	$english_text_raw =~ s/“/"/g;
	$english_text_raw =~ s/\.{4,}/\.\.\./g;
	$english_text_raw =~ s/…/\.\.\./g;
	$english_text_raw =~ s/\.\.\.\!\?/\.\.\.\?\!/g;
	$english_text_raw =~ s/^\s+|\s+$//g;
	$english_text_raw =~ s/<ROCKIN' FLITZER>/<ROCKIN'FLITZER>/g;

	# Extract speaker name for special processing.
	(my $speaker_name) = $english_text_raw =~ /<\s*([^]]+)>/x;
	$speaker_name =~ s/[^A-Za-z&\s']//g;

	if($speaker_name ne "")
	{
		my @speaker_name_characters = split(//, $speaker_name);

		# Append Shift-JIS speaker name to hex data.
		foreach(@speaker_name_characters)
		{
			$english_text_hex .= $sjis_character_map{uc($_)};
		}

		# Append new-line.
		$english_text_hex .= "fd";
		
		# Remove non-printable characters and perform other clean-up.
		$english_text_raw =~ s/<$speaker_name>//g;
		$english_text_raw =~ s/.*[^[:print:]]+//;
		$english_text_raw =~ s/^\s+|\s+$//g;
		$english_text_raw =~ s/[\r\n]+//g;
		$english_text_raw =~ s/ +/ /;
		$english_text_raw =~ s/\s+/ /g;
	}
	elsif($speaker_name eq "" && ($japanese_text =~ /：\n/ || $japanese_text =~ /：\r/))
	{
		print "WARNING: Missing speaker name due to text error!\n";
		system "echo \"[$file_input_basename]\" >> ./warning.log";
		system "echo \"Missing speaker name.\" >> ./warning.log";
		system "echo \"String number $i\n\" >> ./warning.log";
	}

	# Split each whole word (including punctuation) into separate elements of "english_text_words".
	my @english_text_words = split(/ /, $english_text_raw);

	# Apply space character for cells marked "[EMPTY]".
	if($english_text_raw eq "[EMPTY]")
	{
		$english_text_hex .= "20";
	}
	# Otherwise, process text normally.
	else
	{
		# Process custom tile spacing for specific characters and character groups.
		for(my $j = 0; $j < scalar(@english_text_words); $j ++)
		{
			@word_hex = ();
			$word_lengths[$j] = length($english_text_words[$j]) * 16;
			my @english_characters = split(//, $english_text_words[$j]);
			
			# Process a manual cycling of new dialog box.
			if($english_text_words[$j] eq "[NEW-DIALOG-BOX]")
			{
				$line_count = 1;
				$english_text_hex .= "feff00";
				$processing_after_dialog_break = 1;

				# Clear all existing line counts, since new dialog box is being generated.
				for(1 .. 18)
				{
					$line_length[$_] = 0;
				}

				if($speaker_name ne "")
				{
					my @speaker_name_characters = split(//, $speaker_name);

					# Append Shift-JIS speaker name to hex data.
					foreach(@speaker_name_characters)
					{
						$english_text_hex .= $sjis_character_map{uc($_)};
					}

					# Append new-line.
					$english_text_hex .= "fd";
				}
			}
			# Process manual linebreak.
			elsif($english_text_words[$j] eq "[NL]")
			{
				$english_text_hex .= "fd";
				$line_count ++;
			}
			# Process button selection text.
			elsif($english_text_words[$j] =~ /^\[ff2/)
			{
				if($english_text_words[$j] eq "[ff2428]")
				{
					$english_text_hex .= "ff2428";
				}
				elsif($english_text_words[$j] eq "[ff2400]")
				{
					$english_text_hex .= "ff2400";
				}
				elsif($english_text_words[$j] eq "[ff29ff]")
				{
					$english_text_hex .= "ff29ff";
				}
				elsif($english_text_words[$j] =~ /^\[ff290[0-9]\]/)
				{
					(my $temp_hex = $english_text_words[$j]) =~ s/\[|\]//g;
					
					if($file_input_basename ne "YUSAMES.HBN_002_ATL" && $file_input_basename ne "YUSAMES.HBN_003_ATL")
					{
						$english_text_hex .= "fd";
					}

					$english_text_hex .= $temp_hex;
				}

				$line_length[$line_count] = 0;
			}
			# Process script text.
			else
			{
				# Generate control codes for variable-width font.
				for(my $k = 0; $k < scalar(@english_characters); $k ++)
				{
					my $tile_adjustment_flag = 0;

					if($english_characters[$k] eq ",")
					{
						$word_hex[$j] .= "ff2306" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 8;
						$tile_adjustment_flag = 1;
					}

					if($english_characters[$k] eq "'")
					{
						$word_hex[$j] .= "ff2302" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 16;
						$tile_adjustment_flag = 1;
					}

					if(($english_characters[$k] eq "I" || $english_characters[$k] eq "i" || $english_characters[$k] eq "l")
						&& $english_characters[$k + 1] eq "'")
					{
						$word_hex[$j] .= "ff2308" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 4;
						$tile_adjustment_flag = 1;
					}

					if(($english_characters[$k] eq "I" || $english_characters[$k] eq "i" || $english_characters[$k] eq "l")
						&& $english_characters[$k + 1] eq ".")
					{
						$word_hex[$j] .= "ff2307" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 6;
						$tile_adjustment_flag = 1;
					}

					if(($english_characters[$k] eq "I" || $english_characters[$k] eq "i" || $english_characters[$k] eq "l")
						&& $english_characters[$k + 1] eq "!")
					{
						$word_hex[$j] .= "ff2305" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 10;
						$tile_adjustment_flag = 1;
					}

					if(($characters_variable_width_lowercase !~ /\Q$english_characters[$k]\E/ && $characters_variable_width_lowercase !~ /\Q$english_characters[$k]\E/)
						&& ($english_characters[$k] ne "?" && $english_characters[$k] ne "!")
						&& $english_characters[$k] =~ /[A-Za-z]/
						&& $english_characters[$k + 1] eq "!")
					{
						$word_hex[$j] .= "ff2308" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 4;
						$tile_adjustment_flag = 1;
					}

					if(($english_characters[$k] eq "I" || $english_characters[$k] eq "i" || $english_characters[$k] eq "l")
						&& $english_characters[$k + 1] eq "f")
					{
						$word_hex[$j] .= "ff2306" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 8;
						$tile_adjustment_flag = 1;
					}

					if(($english_characters[$k] eq "I" || $english_characters[$k] eq "i" || $english_characters[$k] eq "l")
						&& ($english_characters[$k + 1] eq "I" || $english_characters[$k + 1] eq "i" || $english_characters[$k + 1] eq "l"))
					{
						$word_hex[$j] .= "ff2304" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 12;
						$tile_adjustment_flag = 1;
					}

					if($english_characters[$k] eq "f"
						&& ($english_characters[$k + 1] eq "I" || $english_characters[$k + 1] eq "i" || $english_characters[$k + 1] eq "l"))
					{
						$word_hex[$j] .= "ff2307" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 6;
						$tile_adjustment_flag = 1;
					}

					if($english_characters[$k] eq "J"
						&& ($english_characters[$k + 1] eq "I" || $english_characters[$k + 1] eq "i" || $english_characters[$k + 1] eq "l"))
					{
						$word_hex[$j] .= "ff2306" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 8;
						$tile_adjustment_flag = 1;
					}

					if($english_characters[$k] eq "R"
						&& ($english_characters[$k + 1] eq "I" || $english_characters[$k + 1] eq "i" || $english_characters[$k + 1] eq "l"))
					{
						$word_hex[$j] .= "ff2307" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 6;
						$tile_adjustment_flag = 1;
					}

					if(($english_characters[$k] eq "I" || $english_characters[$k] eq "i" || $english_characters[$k] eq "l" || $english_characters[$k] eq "j")
						&& ($characters_variable_width_lowercase !~ /\Q$english_characters[$k + 1]\E/ && $characters_variable_width_uppercase !~ /\Q$english_characters[$k + 1]\E/)
						&& $english_characters[$k + 1] ne "" && $english_characters[$k + 1] ne "." && $english_characters[$k + 1] ne "!" && $english_characters[$k + 1] ne "'")
					{
						$word_hex[$j] .= "ff2307" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 6;
						$tile_adjustment_flag = 1;
					}

					if(($english_characters[$k] eq "J" || $english_characters[$k] eq "R")
						&& ($characters_variable_width_lowercase !~ /\Q$english_characters[$k + 1]\E/ && $characters_variable_width_uppercase !~ /\Q$english_characters[$k + 1]\E/)
						&& $english_characters[$k + 1] ne "")
					{
						$word_hex[$j] .= "ff2309" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 2;
						$tile_adjustment_flag = 1;
					}

					if(($characters_variable_width_lowercase !~ /\Q$english_characters[$k]\E/ && $characters_variable_width_uppercase !~ /\Q$english_characters[$k]\E/)
						&& $english_characters[$k + 1] eq "f")
					{
						$word_hex[$j] .= "ff2309" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 2;
						$tile_adjustment_flag = 1;
					}

					if(($characters_variable_width_lowercase !~ /\Q$english_characters[$k]\E/ && $characters_variable_width_uppercase !~ /\Q$english_characters[$k]\E/)
						&& $english_characters[$k] ne "'"
						&& ($english_characters[$k + 1] eq "I" || $english_characters[$k + 1] eq "i" || $english_characters[$k + 1] eq "l"))
					{
						$word_hex[$j] .= "ff2307" . ascii_to_hex($english_characters[$k]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 6;
						$tile_adjustment_flag = 1;
					}

					if($english_characters[$k] eq "." && $english_characters[$k + 1] eq "." && $english_characters[$k + 2] eq "."
						&& $english_characters[$k + 3] eq "?" && $english_characters[$k + 4] eq "!")
					{
						$word_hex[$j] .= "ff2306" . ascii_to_hex($english_characters[$k] . $english_characters[$k + 1]) . "ff2300ff2304" . ascii_to_hex($english_characters[$k + 2]) . "ff2300ff2307" . ascii_to_hex($english_characters[$k + 3]) . "ff2300" . ascii_to_hex($english_characters[$k + 4]);
						$word_lengths[$j] -= 0.75 * 34;
						$tile_adjustment_flag = 1;
						$k += 4;
					}
					elsif($english_characters[$k] eq "." && $english_characters[$k + 1] eq "." && $english_characters[$k + 2] eq "."
						&& $english_characters[$k + 3] eq "?")
					{
						$word_hex[$j] .= "ff2306" . ascii_to_hex($english_characters[$k] . $english_characters[$k + 1]) . "ff2300ff2304" . ascii_to_hex($english_characters[$k + 2]) . "ff2300" . ascii_to_hex($english_characters[$k + 3]);
						$word_lengths[$j] -= 0.75 * 28;
						$tile_adjustment_flag = 1;
						$k += 3;
					}
					elsif($english_characters[$k] eq "." && $english_characters[$k + 1] eq "." && $english_characters[$k + 2] eq "."
						&& $english_characters[$k + 3] eq "!")
					{
						$word_hex[$j] .= "ff2306" . ascii_to_hex($english_characters[$k] . $english_characters[$k + 1]) . "ff2300ff2304" . ascii_to_hex($english_characters[$k + 2]) . "ff2300" . ascii_to_hex($english_characters[$k + 3]);
						$word_lengths[$j] -= 0.75 * 28;
						$tile_adjustment_flag = 1;
						$k += 3;
					}
					elsif($english_characters[$k] eq "." && $english_characters[$k + 1] eq "." && $english_characters[$k + 2] eq ".")
					{
						$word_hex[$j] .= "ff2306" . ascii_to_hex($english_characters[$k] . $english_characters[$k + 1]) . "ff2300" . ascii_to_hex($english_characters[$k + 2]);
						$word_lengths[$j] -= 0.75 * 16;
						$tile_adjustment_flag = 1;
						$k += 2;
					}
					elsif($english_characters[$k] eq "!" && $english_characters[$k + 1] eq "!" && $english_characters[$k + 2] eq "!")
					{
						$word_hex[$j] .= "ff2306" . ascii_to_hex($english_characters[$k] . $english_characters[$k + 1]) . "ff2300" . ascii_to_hex($english_characters[$k + 2]);
						$word_lengths[$j] -= 0.75 * 16;
						$tile_adjustment_flag = 1;
						$k += 2;
					}
					elsif($english_characters[$k] eq "!" && $english_characters[$k + 1] eq "!" && $english_characters[$k + 2] ne "!")
					{
						$word_hex[$j] .= "ff2306" . ascii_to_hex($english_characters[$k]) . "ff2300" . ascii_to_hex($english_characters[$k + 1]);
						$word_lengths[$j] -= 0.75 * 8;
						$tile_adjustment_flag = 1;
						$k += 1;
					}
					elsif($english_characters[$k] eq "?" && $english_characters[$k + 1] eq "!")
					{
						$word_hex[$j] .= "ff2307" . ascii_to_hex($english_characters[$k] . $english_characters[$k + 1]) . "ff2300";
						$word_lengths[$j] -= 0.75 * 12;
						$tile_adjustment_flag = 1;
						$k += 1;
					}

					if($tile_adjustment_flag == 0)
					{
						$word_hex[$j] .= ascii_to_hex($english_characters[$k]);
					}
				}

				# Process chapter selection text.
				if($file_input_basename =~ /M_MCHAR/)
				{
					if($j > 0)
					{
						$line_length[$line_count] += 16;
					}

					if($line_length[$line_count] + $word_lengths[$j] <= 384)
					{
						if($j > 0 && $english_text_words[$j - 1] ne "[NL]")
						{
							$english_text_hex .= "20";
						}

						$english_text_hex .= $word_hex[$j];
						$line_length[$line_count] += $word_lengths[$j];
					}
					else
					{
						$line_count ++;

						$english_text_hex .= "fd" . $word_hex[$j];
						$line_length[$line_count] += $word_lengths[$j];
					}
				}
				# Process cutscene subtitle text.
				elsif($file_input_basename =~ /S_[B|G]_[0-9]/)
				{
					if($j > 0)
					{
						$line_length[$line_count] += 16;
						$english_text_hex .= "20";
					}

					$english_text_hex .= $word_hex[$j];
					$line_length[$line_count] += $word_lengths[$j];

					if($line_length[$line_count] + $word_lengths[$j] > 960)
					{
						print "WARNING: Subtitle text exceeds 960 pixels in width!\n";
						system "echo \"[$file_input_basename]\" >> ./warning.log";
						system "echo \"Oversized subtitle text.\" >> ./warning.log";
						system "echo \"String number $i\n\" >> ./warning.log";
					}
				}
				# Process dialog text.
				else
				{
					# Processing last (third) line of a dialog box.
					if($line_count % 3 == 0)
					{
						if($j > 0 && $processing_after_dialog_break != 1)
						{
							$line_length[$line_count] += 16;
						}

						if($line_length[$line_count] + $word_lengths[$j] <= 656)
						{
							if($j > 0 && $processing_after_dialog_break != 1)
							{
								$english_text_hex .= "20";
							}

							$english_text_hex .= $word_hex[$j];
							$line_length[$line_count] += $word_lengths[$j];
						}
						else
						{
							$line_count ++;

							$english_text_hex .= "feff00";

							if($speaker_name ne "")
							{
								my @speaker_name_characters = split(//, $speaker_name);

								# Append Shift-JIS speaker name to hex data.
								foreach(@speaker_name_characters)
								{
									$english_text_hex .= $sjis_character_map{uc($_)};
								}

								$english_text_hex .= "fd";
							}

							$english_text_hex .= $word_hex[$j];
							$line_length[$line_count] += $word_lengths[$j];
						}
					}
					# Processing normal line (first or second).
					else
					{
						if($j > 0 && $processing_after_dialog_break != 1)
						{
							$line_length[$line_count] += 16;
						}

						if($line_length[$line_count] + $word_lengths[$j] <= 720)
						{
							if($j > 0 && $processing_after_dialog_break != 1 && $english_text_words[$j - 1] !~ /^\[ff290[0-9]\]/)
							{
								$english_text_hex .= "20";
							}

							$english_text_hex .= $word_hex[$j];
							$line_length[$line_count] += $word_lengths[$j];
						}
						else
						{
							$line_count ++;

							$english_text_hex .= "fd" . $word_hex[$j];
							$line_length[$line_count] += $word_lengths[$j];
						}
					}

					if($line_count > 3 && $english_text_raw !~ /\[NEW-DIALOG-BOX\]/)
					{
						print "WARNING: Dialog text exceeds three lines!\n";
						system "echo \"[$file_input_basename]\" >> ./warning.log";
						system "echo \"Oversized dialog line.\" >> ./warning.log";
						system "echo \"String number $i\n\" >> ./warning.log";
					}
				}

				$processing_after_dialog_break = 0;
			}
		}
	}

	# Process "dialog format" control codes.
	if($dialog_format =~ "YES_NO_V1")
	{
		$english_text_hex .= "fdfdff2800827882648272ff2801826d826eff28ff";
	}

	if($dialog_format =~ "YES_NO_V2")
	{
		$english_text_hex .= "fdfdff2800827882648272ff2881826d826eff28ff";
	}

	if($dialog_format =~ "YES_NO_V3")
	{
		$english_text_hex .= "fdfdff2800827882648272ff2801826d826eff28ff";
	}

	if($dialog_format =~ "YES_NO_V4")
	{
		$english_text_hex .= "fdfdff2800827882648272ff2801826d826eff28ff";
	}

	if($dialog_format =~ "PRESS_A")
	{
		$english_text_hex .= "fe";
	}

	# Replace ASCII "The Cool Cool Kids" with Shift-JIS equivalent.
	if($file_input_basename =~ /ENDING/)
	{
		$english_text_hex =~ s/2254484520434F4F4C20434F4F4C20FF23074BFF2300FF230749FF2300445322/814A82738267826481408262826E826E826B81408262826E826E826B8140826A826882638272814A/gi;
	}

	# Pad end of data to be evenly divisible by 4 bytes.
	$english_text_hex .= "00";

	while((length($english_text_hex) / 2) % 4 != 0)
	{
		$english_text_hex .= "00";
	}

	$string_hex[$i - 1] = $english_text_hex;

	# Status message.
	(my $dialog_format_display = $dialog_format) =~ s/\n/ - /g;
	print "String $i / Row " . ($i + 1) . " ($dialog_format_display) [" . scalar(@english_text_words) . " words]\n";

	if(scalar(@english_text_words) == 0)
	{
		system "echo \"[$file_input_basename]\" >> ./warning.log";
		system "echo \"Empty dialog line.\" >> ./warning.log";
		system "echo \"String number $i\n\" >> ./warning.log";
	}

	if($speaker_name ne "")
	{
		print uc($speaker_name) . "\n";
	}

	print "$english_text_raw\n----\n";
}

# Formulate output file and folder based on input.
if($file_input_basename =~ /HBN_/)
{
	my $file_output_subfolder = (split /\.HBN_/, $file_input_basename)[0] . ".HBN";
	($file_input_basename = (split /\.HBN_/, $file_input_basename)[1]) =~ s/\.xlsx//g;
	$file_output .= $file_output_subfolder . "/" . $file_input_basename;
	$file_source .= $file_output_subfolder . "/" . $file_input_basename;
	mkdir($folder_output . "/" . $file_output_subfolder);
}
else
{
	$file_output .= $file_input_basename . ".ATL";
	$file_source .= $file_input_basename . ".ATL";
}

# Build output file header and first pointer.
my $file_output_header = substr(&read_bytes($file_source, 68), 0, 80);
$file_output_header .= &endian_swap(&decimal_to_hex(scalar(@spreadsheet_rows), 4));
$file_output_header .= substr(&read_bytes($file_source, 68), 88, 48);
my $offset_pointer = &endian_swap(&decimal_to_hex((length($file_output_header) / 2) + ((scalar(@spreadsheet_rows) - 1) * 4), 4));
my $file_output_hex = $file_output_header . $offset_pointer;

# Append additional pointers per each dialog instance.
for(2 .. scalar(@spreadsheet_rows) - 1)
{
	$offset_pointer = &endian_swap(&decimal_to_hex(hex(&endian_swap($offset_pointer)) + (length($string_hex[$_ - 2]) / 2) + 4, 4));
	$file_output_hex .= $offset_pointer;
}

# Append each dialog instance.
foreach(@string_hex)
{
	$file_output_hex .= &endian_swap(&decimal_to_hex(length($_) / 2, 4));
	$file_output_hex .= $_;
}

# Pad end of file to be evenly divisible by 16 bytes.
while((length($file_output_hex) / 2) % 16 != 0)
{
	$file_output_hex .= "00";
}

# Add 16 bytes of padding to end of file.
for(1 .. 16)
{
	$file_output_hex .= "00";
}

# Write new file.
&write_bytes($file_output, $file_output_hex);

# Status message.
print "New file written to \"$file_output\"\n";

# Subroutine to return hexadecimal representation of a decimal number.
#
# 1st parameter - Decimal number.
# 2nd parameter - Number of bytes with which to represent hexadecimal number.
sub decimal_to_hex
{
	return sprintf("%0" . $_[1] * 2 . "X", $_[0]);
}

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

# Subroutine to read a specified number of bytes (starting at the beginning) of a specified file,
# returning hexadecimal representation of data.
#
# 1st parameter - Full path of file to read.
# 2nd parameter - Number of bytes to read.
sub read_bytes
{
	my $file_to_read = $_[0];
	my $bytes_to_read = $_[1];

	open my $filehandle, '<:raw', "$file_to_read" or die $!;
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

# Subroutine to generate hash mapping ASCII characters to custom hexadecimal values. Source character
# map file should be formatted with each character definition on its own line (<hex>|<ascii>). Example
# character map file:
#  ______
# |      |
# | 00|A |
# | 01|B |
# | 02|C |
# |______|
#
# The ASCII key in the returned hash will contain the custom hexadecimal value (e.g. $hash{'B'} will
# equal "01").
#
# 1st parameter - Full path of character map file.
sub generate_character_map_hash
{
	my $character_map_file = $_[0];
	my %character_table;

	open my $filehandle, '<', $character_map_file or die $!;
	chomp(my @mapped_characters = <$filehandle>);
	close $filehandle;

	foreach(@mapped_characters)
	{
		$character_table{(split /\|/, $_)[1]} = (split /\|/, $_)[0];
	}

	return %character_table;
}