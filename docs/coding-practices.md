# Coding Practices

A simple document detailing various little notes or things to remember.

## Local Character

This game utilizes a singleton-character approach. Since this is a gamejam, the easiest method for handling the character is to never destroy/kill them. Once we are done with them,
we kick them and force them to rejoin. This allows us to avoid all character-related bugs with respawning. Piggybacking off of that, we will never need to update variables in regards
to the character because the player will only ever have one character!
