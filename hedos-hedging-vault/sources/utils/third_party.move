module delta_hedging::third_party {
    use std::string::{Self, String};
    use std::vector;

    struct ThirdParty has copy, drop, store {
        type: u8,
        collateral_delta: u64, leverage: u64, is_long: bool, market_skew: bool, pair: String,
        amount_withdraw: u64, token_withdraw: String, 
        amount_repay: u64, token_repay: String,
        action: u8,
    }

    #[view]
    public fun new_perp_action(
        collateral_delta: u64, 
        leverage: u64, 
        is_long: bool, 
        market_skew: bool,
    ): ThirdParty {
        ThirdParty {
            type: perp_id(),
            collateral_delta, leverage, is_long, market_skew, pair: empty_string(),
            amount_withdraw: 0, token_withdraw: empty_string(),
            amount_repay: 0, token_repay: empty_string(),
            action: 0
        }
    }
    
    #[view]
    public fun new_perp(
        collateral_delta: u64, 
        leverage: u64, 
        is_long: bool, 
        market_skew: bool,
    ): vector<u64> {
        let  vec: vector<u64> = vector[];
        vector::push_back(&mut vec, perp_id() as u64);
        vector::push_back(&mut vec, collateral_delta);
        vector::push_back(&mut vec, leverage);
        vector::push_back(&mut vec, if (is_long) 1 else 0);
        vector::push_back(&mut vec, if (market_skew) 1 else 0);
        vec
    }

    #[view]
    public fun new_liquid(
        amount_withdraw: u64,
    ): vector<u64> {
        let vec: vector<u64> = vector[];
        vector::push_back(&mut vec, liquid_id() as u64);
        vector::push_back(&mut vec, amount_withdraw);
        vec
    }

    #[view]
    public fun new_lending(
        amount_withdraw: u64,
        token_withdraw: String,
        amount_repay: u64, 
        token_repay: String,
        action: u8,
    ): vector<u64> {
        let vec: vector<u64> = vector[];
        vector::push_back(&mut vec, lending_id() as u64);
        vector::push_back(&mut vec, amount_withdraw);
        vector::push_back(&mut vec, get_token_id(token_withdraw));
        vector::push_back(&mut vec, amount_repay);
        vector::push_back(&mut vec, get_token_id(token_repay));
        vector::push_back(&mut vec, action as u64);
        vec
    }

    public fun unzip_input(data: vector <u64>): vector<ThirdParty> {
        let i = 0;
        let len = vector::length(&data);
        let result: vector<ThirdParty> = vector[];
        while (i < len) {   
            let type_id = *vector::borrow(&data, i) as u8;
            if (type_id == perp_id()) {
                let collateral_delta = *vector::borrow(&data, i + 1);
                let leverage = *vector::borrow(&data, i + 2);
                let is_long = *vector::borrow(&data, i + 3) != 0;
                let market_skew = *vector::borrow(&data, i + 4) != 0;
                let tp = new_perp_action(
                    collateral_delta, leverage, is_long, market_skew
                );
                vector::push_back(&mut result, tp);
                i += 5;
            } else if (type_id == liquid_id()) {
                let amount_withdraw = *vector::borrow(&data, i + 1);
                let tp = new_liquid_action(amount_withdraw);
                vector::push_back(&mut result, tp);
                i += 2;
            } else if (type_id == lending_id()) {
                let amount_withdraw = *vector::borrow(&data, i + 1);
                let token_withdraw = get_token_string(*vector::borrow(&data, i + 2));
                let amount_repay = *vector::borrow(&data, i + 3);
                let token_repay = get_token_string(*vector::borrow(&data, i + 4));
                let action = *vector::borrow(&data, i + 5) as u8;
                let tp = new_lending_action(amount_withdraw, token_withdraw, amount_repay, token_repay, action);
                vector::push_back(&mut result, tp);
                i += 6;
            } else {
                abort 1;
            }
        };
        result
    }

    #[view]
    public fun check_unzip(data: vector<u64>): u64 {
        let tp = unzip_input(data);
        let i = 0;
        let len = vector::length(&tp);
        let sum = 0;
        while (i < len) {
            let x = vector::borrow(&tp, i);
            sum += get_type_id(x) as u64;
            i += 1;
        };
        sum
    }

    #[view]
    public fun get_token_id(token: String): u64 {
        if (token == string::utf8(b"USDC")) {
            1
        } else if (token == string::utf8(b"APT")) {
            2
        } else {
            abort 1
        }
    }

    #[view]
    public fun get_token_string(token_id: u64): String {
        if (token_id == 1) {
            string::utf8(b"USDC")
        } else if (token_id == 2) {
            string::utf8(b"APT")
        } else {
            abort 1
        }
    }


    #[view]
    public fun new_liquid_action(
        amount_withdraw: u64, 
    ): ThirdParty {
        ThirdParty {
            type: liquid_id(),
            collateral_delta: 0, leverage: 0, is_long: false, market_skew: false, pair: empty_string(),
            amount_withdraw, token_withdraw: empty_string(),
            amount_repay: 0, token_repay: empty_string(),
            action: 0
        }
    }

    #[view]
    public fun new_lending_action(
        amount_withdraw: u64,
        token_withdraw: String,
        amount_repay: u64, 
        token_repay: String,
        action: u8,
    ): ThirdParty {
        ThirdParty {
            type: lending_id(),
            collateral_delta: 0, leverage: 0, is_long: false, market_skew: false, pair: empty_string(),
            amount_withdraw, token_withdraw,
            amount_repay, token_repay,
            action
        }
    }

    public fun get_type_id(tp: &ThirdParty): u8 {
        tp.type
    }

    public fun get_action_id(tp: &ThirdParty): u8 {
        tp.action
    }

    public fun get_perp_param(tp: &ThirdParty): (u64, u64, bool, bool) {
        assert!(tp.type == perp_id(), 0);
        (tp.collateral_delta, tp.leverage, tp.is_long, tp.market_skew)
    }

    public fun get_liquid_param(tp: &ThirdParty): u64 {
        assert!(tp.type == liquid_id(), 0);
        tp.amount_withdraw
    }

    public fun get_lending_param(tp: &ThirdParty): (u64, String, u64, String, u8) {
        assert!(tp.type == lending_id(), 0);
        (tp.amount_withdraw, tp.token_withdraw, tp.amount_repay, tp.token_repay, tp.action)
    }

    fun empty_string(): string::String {
        string::utf8(b"")
    }
    
    public fun perp_id(): u8 {
        1
    }

    public fun liquid_id(): u8 {
        2
    }

    public fun lending_id(): u8 {
        3
    }

    public fun only_withdraw_id(): u8 {
        1
    }

    public fun repay_withdraw_id(): u8 {
        2
    }


    public fun check(actions: vector<ThirdParty>): u64 {
        let i = 0;
        let len = actions.length();
        let sum = 0;
        while (i < len) {
            let x = actions.borrow(i);
            sum += get_type_id(x) as u64;
            i = i + 1;
        };
        sum
    }

    #[view]
    public fun checkString(s: String): bool {
        s == string::utf8(b"APT")
    }

    #[view]
    public fun stringAPT(): string::String {
        string::utf8(b"APT")
    }

    #[view]
    public fun stringUSDC(): string::String {
        string::utf8(b"USDC")
    }
}