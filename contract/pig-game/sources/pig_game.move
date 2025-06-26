/// Each turn, a player repeatedly rolls a die until a 1 is rolled or the player decides to "hold":
///
/// If the player rolls a 1, they score nothing and it becomes the next player's turn.
/// If the player rolls any other number, it is added to their turn total and the player's turn continues.
/// If a player chooses to "hold", their turn total is added to their score, and it becomes the next player's turn.
/// The first player to score 100 or more points wins.
///
/// Your task:
/// - Implement the pig game here
/// - Integrate it with the pig master contract
/// - Test it with the frontend
module pig_game_addr::pig_game {

    use pig_master_addr::pig_master;
    use aptos_framework::randomness;

    const E_UNTIL_SCORE_IS_50: u64 = 1;
    const E_NOT_IMPLEMENTED: u64 = 2;

    struct GlobalState has key {
        game_played: u64,
        min_turns: u64,
    }


    struct GameState has key  {
        round: u64,
        turns: u64,
        total_score: u64,
        turn_score: u64,
        last_roll: u64
    }


    // ======================== Entry (Write) functions ========================
    #[randomness]
    /// Roll the dice
    entry fun roll_dice(user: &signer) acquires GameState {
        let result = randomness::u64_range(1,7);
        let game_state = borrow_global_mut<GameState>(@pig_game_addr);
        game_state.round = game_state.round + 1;
        game_state.last_roll = result;
        if (result == 1) {
            game_state.turn_score = 0;
            game_state.turns = game_state.turns + 1;
        } else {
            game_state.turn_score = game_state.turn_score + result;
        }
    }

    #[test_only]
    /// Optional, useful for testing purposes
    fun roll_dice_for_test(user: &signer, num: u8) acquires GameState {
        let game_state = borrow_global_mut<GameState>(@pig_game_addr);
        game_state.round = game_state.round + 1;
        game_state.last_roll = (num as u64);
        if (num == 1) {
            game_state.turn_score = 0;
            game_state.turns = game_state.turns + 1;
        } else {
            game_state.turn_score = game_state.turn_score + (num as u64);
        }
    }

    /// End the turn by calling hold, add points to the overall
    /// accumulated score for the current game for the specified user
    entry fun hold(user: &signer) acquires GameState {
        let game_state = borrow_global_mut<GameState>(@pig_game_addr);
        game_state.total_score = game_state.total_score + game_state.turn_score;
        game_state.turn_score = 0;
        game_state.turns = game_state.turns + 1;
    }

    /// The intended score has been reached, end the game, publish the
    /// score to both the global storage
    entry fun complete_game(user: &signer) acquires GameState, GlobalState {
        let game_state = borrow_global<GameState>(@pig_game_addr);
        assert!(game_state.total_score >= pig_master::points_to_win(), E_UNTIL_SCORE_IS_50);
        
        // Update global games played counter
        let global_state = borrow_global_mut<GlobalState>(@pig_game_addr);
        global_state.game_played = global_state.game_played + 1;
    }

    /// The user wants to start a new game, end this one.
    entry fun reset_game(user: &signer) acquires GameState {
        let game_state = borrow_global_mut<GameState>(@pig_game_addr);
        game_state.round = 0;
        game_state.turns = 0;
        game_state.total_score = 0;
        game_state.turn_score = 0;
        game_state.last_roll = 0;
    }

    // ======================== View (Read) Functions ========================

    #[view]
    /// Return the user's last roll value from the current game, 0 is considered no roll / hold
    public fun last_roll(user: address): u8 acquires GameState {
        (borrow_global<GameState>(@pig_game_addr).last_roll as u8)
    }

    #[view]
    /// Tells us which number round the game is on, this only resets when the game is reset
    ///
    /// This increments every time the user rolls the dice or holds
    public fun round(user: address): u64 acquires GameState {
        borrow_global<GameState>(@pig_game_addr).round
    }

    #[view]
    /// Tells us which number turn the game is on, this only resets when the game is reset
    ///
    /// This increments every time the user rolls a 1 or holds
    public fun turn(user: address): u64 acquires GameState {
        borrow_global<GameState>(@pig_game_addr).turns
    }

    #[view]
    /// Tells us whether the game is over for the user (the user has reached the target score)
    public fun game_over(user: address): bool acquires GameState {
        let game_state = borrow_global<GameState>(@pig_game_addr);
        game_state.total_score >= pig_master::points_to_win()
    }

    #[view]
    /// Return the user's current turn score, this is the score accumulated during the current turn.  If the player holds
    /// this score will be added to the total score for the game.
    public fun turn_score(user: address): u64 acquires GameState {
        borrow_global<GameState>(@pig_game_addr).turn_score
    }

    #[view]
    /// Return the user's current total game score for the current game, this does not include the current turn score
    public fun total_score(user: address): u64 acquires GameState {
        borrow_global<GameState>(@pig_game_addr).total_score
    }

    #[view]
    /// Return total number of games played within this game's context
    public fun games_played(): u64 acquires GlobalState {
        borrow_global<GlobalState>(@pig_game_addr).game_played
    }

    #[view]
    /// Return total number of games played within this game's context for the given user
    public fun user_games_played(user: address): u64 {
        // Since we don't track per-user game count in the struct, return 0 for now
        // This would need the struct to be modified to track this properly
        0
    }
}
