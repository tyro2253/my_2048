#!/usr/bin/env bash

# important variables
declare -ia board    # array that keeps track of game status
declare -i pieces    # number of pieces present on board
declare -i score=0   # score variable
declare -i flag_skip # flag that prevents doing more than one operation on
                     # single field in one step
declare -i moves     # stores number of possible moves to determine if player lost
                     # the game
declare ESC=$'\e'    # escape byte
declare header="Bash 2048 v1.1,RRR"

declare -i start_time
start_time=$(date +%s)

# default config
declare -i board_size=4
declare -i target=2048
declare -i reload_flag=0
declare config_dir="$HOME/.bash2048"

# for colorizing numbers
declare -a colors
colors[2]=33
colors[4]=32
colors[8]=34
colors[16]=36
colors[32]=35
colors[64]="33m\033[7"
colors[128]="32m\033[7"
colors[256]="34m\033[7"
colors[512]="36m\033[7"
colors[1024]="35m\033[7"
colors[2048]="31m\033[7"

exec 3>/dev/null  # no logging by default

trap "end_game 0 1" INT  # handle INT signal

# print current status of the game; last added piece is marked red
function print_board {
  clear
  printf "%s pieces=%d target=%d score=%d\n" "$header" "$pieces" "$target" "$score"
  printf "Board status:\n" >&3
  printf "\n"
  printf '/------'
  for (( l=1; l<=index_max; l++ )); do
    printf '+------'
  done
  printf '\\\n'
  for (( l=0; l<=index_max; l++ )); do
    printf '|'
    for (( m=0; m<=index_max; m++ )); do
      local idx=$(( l*board_size + m ))
      if (( board[idx] )); then
        if (( last_added == idx || first_round == idx )); then
          printf '\033[1m\033[31m %4d \033[0m|' "${board[idx]}"
        else
          printf "\033[1m\033[${colors[${board[idx]}]}m %4d\033[0m |" "${board[idx]}"
        fi
        printf " %4d |" "${board[idx]}" >&3
      else
        printf '      |'
        printf '      |' >&3
      fi
    done
    if (( l != index_max )); then
      printf '\n|------'
      for (( l2=1; l2<=index_max; l2++ )); do
        printf '+------'
      done
      printf '|\n'
      printf '\n' >&3
    fi
  done
  printf '\n\\------'
  for (( l=1; l<=index_max; l++ )); do
    printf '+------'
  done
  printf '/\n'
}

# Generate a new piece on the board.
# Collects all empty cells first, then picks one at random — O(n) guaranteed.
# inputs:  $board, $pieces
# outputs: $board, $pieces, $last_added
function generate_piece {
  local -a empty_cells=()
  for (( i=0; i<fields_total; i++ )); do
    (( board[i] == 0 )) && empty_cells+=("$i")
  done
  local pos="${empty_cells[$(( RANDOM % ${#empty_cells[@]} ))]}"
  local value=$(( RANDOM % 10 ? 2 : 4 ))
  board[$pos]=$value
  last_added=$pos
  printf "Generated new piece with value %d at position [%d]\n" "$value" "$pos" >&3
  (( pieces++ ))
}

# Perform push operation between two pieces.
# inputs:
#   $1 - push position (row for horizontal push, column for vertical)
#   $2 - recipient piece index (holds result after move/join)
#   $3 - originator piece index (emptied after move/join)
#   $4 - direction: "up", "down", "left", or "right"
#   $5 - if set, only count valid moves without modifying the board
#   $board - current board state
# outputs:
#   $change    - set if the board was modified
#   $flag_skip - set to prevent further modification of the recipient this step
#   $board     - updated board state
function push_pieces {
  local first second
  case $4 in
    "up")
      (( first  =  $2      * board_size + $1 ))
      (( second = ($2 + $3) * board_size + $1 ))
      ;;
    "down")
      (( first  = (index_max - $2)      * board_size + $1 ))
      (( second = (index_max - $2 - $3) * board_size + $1 ))
      ;;
    "left")
      (( first  = $1 * board_size +  $2      ))
      (( second = $1 * board_size + ($2 + $3) ))
      ;;
    "right")
      (( first  = $1 * board_size + (index_max - $2)      ))
      (( second = $1 * board_size + (index_max - $2 - $3) ))
      ;;
  esac

  if (( ! board[first] )); then
    if (( board[second] )); then
      if [ -z "$5" ]; then
        board[$first]=${board[$second]}
        board[$second]=0
        (( change=1 ))
        printf "move piece with value %d from [%d] to [%d]\n" \
          "${board[$first]}" "$second" "$first" >&3
      else
        (( moves++ ))
      fi
    fi
    return
  fi

  (( board[second] )) && (( flag_skip=1 ))

  if (( board[first] == board[second] )); then
    if [ -z "$5" ]; then
      (( board[first] *= 2 ))
      (( board[first] == target )) && end_game 1
      board[$second]=0
      (( pieces-- ))
      (( change=1 ))
      (( score += board[first] * 2))
      printf "joined piece from [%d] with [%d], new value=%d\n" \
        "$second" "$first" "${board[$first]}" >&3
    else
      (( moves++ ))
    fi
  fi
}

function apply_push {
  printf "\n\ninput: %s key\n" "$1" >&3
  for (( i=0; i<=index_max; i++ )); do
    for (( j=0; j<=index_max; j++ )); do
      flag_skip=0
      local increment_max=$(( index_max - j ))
      for (( k=1; k<=increment_max; k++ )); do
        (( flag_skip )) && break
        push_pieces "$i" "$j" "$k" "$1" "$2"
      done
    done
  done
}

function check_moves {
  (( moves=0 ))
  apply_push up   fake
  apply_push down fake
  apply_push left fake
  apply_push right fake
}

function key_react {
  (( change=0 ))
  read -d '' -sn 1
  if test "$REPLY" = "$ESC"; then
    read -d '' -sn 1 -t1
    if test "$REPLY" = "["; then
      read -d '' -sn 1 -t1
      case $REPLY in
        A) apply_push up;;
        B) apply_push down;;
        C) apply_push right;;
        D) apply_push left;;
      esac
    fi
  else
    case $REPLY in
      k|w) apply_push up;;
      j|s) apply_push down;;
      l|d) apply_push right;;
      h|a) apply_push left;;
    esac
  fi
}

# Save game state atomically: write to a temp dir, then rename into place.
# This ensures the save is never left in a partially-written state.
function save_game {
  local tmp_dir
  tmp_dir=$(mktemp -d "${config_dir}.tmp.XXXXXX")
  echo "${board[@]}"  > "$tmp_dir/board"
  echo "$board_size"  > "$tmp_dir/board_size"
  echo "$pieces"      > "$tmp_dir/pieces"
  echo "$target"      > "$tmp_dir/target"
  echo "$score"       > "$tmp_dir/score"
  echo "$first_round" > "$tmp_dir/first_round"
  rm -rf "$config_dir"
  mv "$tmp_dir" "$config_dir"
}

function reload_game {
  printf "Loading saved game...\n" >&3

  if [ ! -d "$config_dir" ]; then
    return
  fi

  board=($(cat "$config_dir/board"))
  board_size=$(cat "$config_dir/board_size")
  pieces=$(cat "$config_dir/pieces")
  first_round=$(cat "$config_dir/first_round")
  target=$(cat "$config_dir/target")
  score=$(cat "$config_dir/score")

  (( fields_total = board_size * board_size ))
  (( index_max    = board_size - 1 ))
}

function end_game {
  local end_time total_time
  end_time=$(date +%s)
  (( total_time = end_time - start_time ))

  print_board
  printf "Your score: %d\n" "$score"
  printf "This game lasted "

  if date --version > /dev/null 2>&1; then
    date -u -d "@${total_time}" +%T
  else
    date -u -r "${total_time}" +%T
  fi

  stty echo

  if (( $1 )); then
    printf "Congratulations you have achieved %d\n" "$target"
    exit 0
  fi

  if [ -z "$2" ]; then
    read -n1 -p "Do you want to overwrite saved game? [y|N]: "
    if test "$REPLY" = "Y" || test "$REPLY" = "y"; then
      save_game
      printf "\nGame saved. Use -r option next time to load this game.\n"
      exit 0
    fi
    printf "\nGame not saved.\n"
    exit 0
  fi

  printf "\nYou have lost, better luck next time.\033[0m\n"
  exit 0
}

function help {
  cat <<END_HELP
Usage: $1 [-b INTEGER] [-t INTEGER] [-l FILE] [-r] [-h]

  -b    specify game board size (sizes 3-9 allowed)
  -t    specify target score to win (needs to be power of 2)
  -l    log debug info into specified file
  -r    reload the previous game
  -h    this help

END_HELP
}

# parse command-line options
while getopts "b:t:l:rh" opt; do
  case $opt in
    b)
      board_size="$OPTARG"
      if ! (( board_size >= 3 && board_size <= 9 )); then
        printf "Invalid board size, please choose size between 3 and 9\n"
        exit 1
      fi
      ;;
    t)
      target="$OPTARG"
      printf "obase=2;%d\n" "$target" | bc | grep -qe '^1[^1]*$'
      if (( $? )); then
        printf "Invalid target, has to be power of two\n"
        exit 1
      fi
      ;;
    r) reload_flag=1;;
    h) help "$0"; exit 0;;
    l) exec 3>"$OPTARG";;
    \?) printf "Invalid option: -%s, try %s -h\n" "$opt" "$0" >&2; exit 1;;
    :)  printf "Option -%s requires an argument, try %s -h\n" "$opt" "$0" >&2; exit 1;;
  esac
done

# initialise board
(( fields_total = board_size * board_size ))
(( index_max    = board_size - 1 ))
for (( i=0; i<fields_total; i++ )); do board[$i]=0; done
pieces=0
generate_piece
first_round=$last_added
generate_piece

# load saved game if flag is set
if (( reload_flag )); then
  reload_game
fi

# main game loop
while true; do
  print_board
  key_react
  (( change )) && generate_piece
  first_round=-1
  if (( pieces == fields_total )); then
    check_moves
    (( moves == 0 )) && end_game 0
  fi
done
