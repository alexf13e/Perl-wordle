
#!/usr/bin/perl
use warnings;
use strict;
use Term::ANSIScreen qw/:color :cursor :screen/;

sub read_file_lines_to_hash
{
    open(my $file, "<", $_[0]) or die "Failed to open file: $_[0]\n";
    my @contents = <$file>;
    chomp(@contents);
    return map { $_ => $_ } @contents; # fill the hash with the key and value being a given word
}

my %answer_words = read_file_lines_to_hash("./wordle-La.txt");
my %guessable_words = read_file_lines_to_hash("./wordle-Ta.txt");

my %letter_states = map { $_ => 0 } ("a".."z"); # hash map of each letter starting with a state of 0 (not used in a guess)
my @keyboard_state_colours = ("dark white", "black", "bold white"); # colours to print keyboard letters for unused, not in word, in word

my $max_guesses = 6;
my $current_guess_num = 1;

my $answer = $answer_words{(keys %answer_words)[rand keys %answer_words]}; # pick a random word from the potential answer words
my $answer_len = length($answer);


print("Wordle - Guess the word in $max_guesses attempts or fewer (type q to quit) - The word has $answer_len letters\n");

while ($current_guess_num <= $max_guesses)
{
    # print the keyboard
    cldown();
    print("\n\n");

    # qwerty keyboard rows, modify as needed for other layouts
    my @row1 = qw(q w e r t y u i o p);
    my @row2 = qw(a s d f g h j k l);
    my @row3 = qw(z x c v b n m);

    for my $letter (@row1)
    {
        my $colour = $keyboard_state_colours[$letter_states{$letter}];
        print(colored("$letter ", $colour));
    }

    print("\n "); # newline and a space to pad the next row over
    for my $letter (@row2)
    {
        my $colour = $keyboard_state_colours[$letter_states{$letter}];
        print(colored("$letter ", $colour));
    }

    print("\n  ");
    for my $letter (@row3)
    {
        my $colour = $keyboard_state_colours[$letter_states{$letter}];
        print(colored("$letter ", $colour));
    }

    left(scalar(@row3) * 2 + 2); # move back to start of line (7 letters with 1 space each, + 2 spaces at the start)

    # move back up to where cursor was before printing keyboard.
    # cannot save/load pos as may have been at bottom of screen and caused a scroll
    up(4);


    # prompt user for guess
    print("$current_guess_num: ");
    savepos(); # save cursor position for writing error messages and colouring guess
    
    my $guess = <STDIN>;
    chomp($guess);
    $guess = lc($guess); # convert input to lower case for processing

    if ($guess eq "q")
    {
        cldown(); # clear keyboard from screen
        exit(1);
    }

    if (length($guess) != $answer_len)
    {
        # if guess doesn't have the right amount of letters, don't bother with any further checks and don't take away a guess
        loadpos();
        print("$guess - ", colored("Guess must have $answer_len letters\n", "red"));
        next;
    }

    if ($guess eq $answer)
    {
        # if guess matches answer, no need to do further checks on it
        loadpos();
        print(colored("$guess\n", "green"));
        print("You guessed the word\n");
        last;
    }

    if (!exists($answer_words{$guess}) && !exists($guessable_words{$guess}))
    {
        # the guess does not exist in the list of answers or of other guessable words
        loadpos();
        print("$guess ", colored("is not a valid word\n", "red"));
        next;
    }

    my @answer_chars = split(//, $answer); # // is a regex matching anything, so each character is returned as a match in an array
    my @guess_chars = split(//, $guess);

    loadpos(); # load cursor positon to re-write word over user input in colour
    my @indices = (0..$answer_len-1);
    for my $i (@indices)
    {
        my $char = $guess_chars[$i];
        if ($char eq $answer_chars[$i]) # exact match for this character and position
        {
            print(colored($char, "green"));
            $letter_states{$char} = 2; # highlight letter on keyboard
        }
        elsif (index($answer, $char) != -1) # partial match (character is in word but not at this position)
        {
            print(colored($char, "yellow"));
            $letter_states{$char} = 2; # highlight letter on keyboard
        }
        else # no match
        {
            print(colored($char, "dark white"));
            $letter_states{$char} = 1; # hide letter from keyboard
        }
    }
    print("\n");

    $current_guess_num++;
}

if ($current_guess_num >= $max_guesses + 1)
{
    print("Ran out of guesses, the word was $answer\n");
}

cldown(); # clear keyboard from screen
