:-consult('terminal.pl').
:-consult('logic.pl').

:- use_module(library(random)).

% play/0
% Predicate that starts the application.
play :- main_menu.

% main_menu/0
% Displays a menu with various options. Loops until it receives a valid input.
main_menu :- repeat,
             format('What would you like to do?~n1- Choose gamemode~n2- Start the game~n3- Exit the program~nDo not forget to add a dot after every input!~n', []),
             read(Option),
             (
                Option = 4, main_menu(Option);
                main_menu(Option), false
             ).


% main_menu(+Option)
% Calls the appropriate function based on the option chosen.
main_menu(1) :- set_gamemode.
main_menu(2) :- start.
main_menu(3) :- write('Goodbye!').

% start/0
% Starts the game, initializing the board and entering the game loop.
start :- size(Size),
         total_pieces(Pieces),
         initial_state(Size, GameState),
         % display_game(GameState),
         gamemode(PlayerOneType/_),
         game_loop(GameState-PlayerOneType, Pieces).

% game_loop(+GamePhase, +TurnsLeft)
% The game's main loop.
% Verifies that the game is not over, either by victory or lack of playable pieces (which ends the game in a Draw),
% then asks the player for a move, switching players afterward and rendering the new board.
% On game over, the loop ends.
game_loop(GameState-PlayerType, TurnsLeft) :- game_over(GameState, Winner, TurnsLeft), !,
                                              winner_message(Winner),
                                              format('~n~nGAME OVER~n~n',[]).
game_loop(GameState-PlayerType, TurnsLeft) :- ask_move(GameState, PlayerType, PieceMove, piece, TurnsLeft),
                                   move(GameState, PieceMove, piece, MidGameState),
                                   ask_move(MidGameState, PlayerType, StackMove, PieceMove, stack, TurnsLeft),
                                   move(MidGameState, StackMove, PieceMove, stack, NewGameState),
                                   NewTurnsLeft is TurnsLeft-1,
                                   next_player_type(PlayerType, NextPlayerType),
                                   display_game(NewGameState), !,
                                   game_loop(NewGameState-NextPlayerType, NewTurnsLeft).

% ask_move(+GameState, +PlayerType, -Move, +TurnsLeft)
% Asks a human player for a move, or makes the computer choose a move depending on its difficulty.
ask_move(Board-Player, h, Row/Col, piece, TurnsLeft) :- repeat,
                                                         format('~nTurns left: ~w. If no one wins in the remaining turns, the game will end in a draw.', [TurnsLeft]),
                                                         format('~nTime to move, ~w. Where will you place your stone? (Input in "Row/Col" format)~n', [Player]),
                                                         read(Row/Col),
                                                         number(Row), number(Col),
                                                         Row > 0, Col > 0,
                                                         move(Board-Player, Row/Col, piece, _).
ask_move(Board-Player, ComputerLevel, Placement, piece, TurnsLeft) :- choose_move(ComputerLevel, Board-Player, Placement, piece),
                                                                 format('Beep. I place my piece here: ~w', [Placement]).
ask_move(Board-Player, h, Move, PieceMove, stack, TurnsLeft) :- repeat,
                                                               get_stack(Board, PieceMove, Stack),
                                                               format('~nStack to be moved: ~w~n~n', [Stack]),
                                                               format('~w, where will you move your stack? (Input a string of characters X, such that:~n', [Player]),
                                                               format('X is formed by "n", "s", "w" or "e" (North, South, East, West), and you cannot move to where you were directly before (Which means no "ns", "ew", "we", etc.).~n',[]),
                                                               format('Make sure the length of your string matches the length of the stack you are moving.~n',[]),
                                                               format('The first piece to be placed is the one on the right.~n',[]),
                                                               read(Move),
                                                               move(Board-Player, Move, PieceMove, stack, _).
ask_move(Board-Player, ComputerLevel, Move, PieceMove, stack, TurnsLeft) :- choose_move(ComputerLevel, Board-Player, Move, PieceMove, stack),
                                                                format('~nBoop. I move the stack like this: ~w~n~n', [Move]).

choose_move(c1, GameState, Placement, piece) :- valid_moves(GameState, Moves), 
                                          random_select(Placement, Moves, _).
choose_move(c2, GameState, Placement, piece) :- setof(Value-Move, NewState^(move(GameState, Move, piece, NewState), 
                                                value(NewState, Move, Value) ), Results),
                                                last(Results, _-Placement).
choose_move(c1, GameState, Move, Row/Col, stack) :- valid_moves(GameState, Moves, Row/Col),
                                                    random_select(Move, Moves, _).
choose_move(c2, Board-Player, Move, Row/Col, stack) :- get_stack(Board, Move, Stack),
                                                      setof(Value-Move, NewState^(move(GameState, Move, Row/Col, stack, NewState), 
                                                      value(NewState, Value)), Results),
                                                      last(Results, _-Placement).


winner_message(triangle) :- format('You are a player of acute intelligence. Nice win, triangle!',[]).
winner_message(circle) :- format('A round of applause to the winner: circle!',[]).
winner_message(draw) :- format('After a true display of skill, the match unfortunately ends in a draw.',[]).
