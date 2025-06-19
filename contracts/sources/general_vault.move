module delta_hedging::general_vault {
    use aptos_framework::table::{Self, Table};
    use aptos_framework::event::{emit};
    use aptos_framework::object::{Self, ExtendRef};

    use std::signer::{Self};
    use std::string::{String};

    use delta_hedging::math::{I64, init_i64, get_value, is_negative, add, sub};
    use delta_hedging::white_list::{only_admin};
    use delta_hedging::token::{transfer_usdc};
    use delta_hedging::interact_merkle_trade::{simple_trade};
    use delta_hedging::interact_amnis::{stake, unstake_amAPT, price_stAPT};

    use delta_hedging::interact_cellana::{swap_USDC_to_APT,swap_USDC_to_APTv2, swap_amAPT_to_USDC, get_amounts_out_USDC_APT_cellana, get_amounts_out_APT_USDC_cellana};
    const DELTA_HEDGING: address = @delta_hedging;
    const PRECISION: u128 = 100000000;

    // const PAIR: String = String::utf8(b"APT_USD");
    use std::string;

    const NOT_ENOUGH_SHARE: u64 = 997;

    fun get_pair(): string::String {
        string::utf8(b"APT_USD")
    }

    #[event]
    struct CreateNewVault has drop, store {
        new_vault_address: address
    }

    struct Vault has key {
        total_value_lock: u64,
        total_share_of_safety_vault: u64,
        users_share_in_safety_vault: Table<address, u64>,
        total_share_of_risky_vault: u64,
        users_share_in_risky_vault: Table<address, u64>,
    
        users_amount_in_safety_vault: Table<address, u64>,
        users_amount_in_risky_vault: Table<address, u64>,
        users_amount_fee_in_safety_vault: Table<address, I64>,
        users_amount_fee_in_risky_vault: Table<address, I64>,

        total_perpeptual: u64,
        total_staked: u64,

        fund_fee: I64,
        fund_fee_risky_rate_numerator: u64,
        fund_fee_risky_rate_denominator: u64, 
    }

    struct VaultRef has key {
        vault_address: address,
        vault_extend_ref: ExtendRef,
    }

    #[event]
    struct Deposited has drop, store {
        account: address,
        amount: u64,
        is_risky: bool,
    }

    #[event]
    struct Withdrawn has drop, store {
        account: address,
        amount: u64,
        is_risky: bool,
    }

    #[event]
    struct OpenPerp has drop, store {
        collateral_delta: u64,
        leverage: u64,
        pair: String
    }

    #[event]
    struct Stake has drop, store {
        amount: u64
    }

    #[view]
    public fun get_vault_address(): address acquires VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        vault_ref.vault_address
    }
    #[view]
    public fun get_total_value_lock(): u64 acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global<Vault>(vault_ref.vault_address);
        vault.total_value_lock
    }
    #[view]
    public fun get_total_staked(): u64 acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global<Vault>(vault_ref.vault_address);
        vault.total_staked
    }
    #[view]
    public fun get_total_perpeptual(): u64 acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global<Vault>(vault_ref.vault_address);
        vault.total_perpeptual
    }

    #[view]
    public fun test(): u64 {
        100
    }


    public entry fun init_vault(signer: &signer) acquires VaultRef {
        // only_admin(signer);

        let constructor_ref = &object::create_object(DELTA_HEDGING);
        let vault_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let new_vault_address = signer::address_of(vault_signer);

        let new_vault = Vault {
            total_value_lock: 0,
            total_share_of_safety_vault: 0,
            total_share_of_risky_vault: 0,
            users_share_in_safety_vault: table::new<address, u64>(),
            users_share_in_risky_vault: table::new<address, u64>(),
            users_amount_in_risky_vault: table::new<address, u64>(),
            users_amount_in_safety_vault: table::new<address, u64>(),
            users_amount_fee_in_risky_vault: table::new<address, I64>(),
            users_amount_fee_in_safety_vault: table::new<address, I64>(),
            total_perpeptual: 0,
            total_staked: 0,
            fund_fee: init_i64(0, false),
            fund_fee_risky_rate_numerator: 0,
            fund_fee_risky_rate_denominator: 0,
        };

        move_to(vault_signer, new_vault);   

        if (!exists<VaultRef>(DELTA_HEDGING)) {
            move_to(signer, VaultRef {
                vault_address: new_vault_address,
                vault_extend_ref: extend_ref,
            })
        } else {
            let vault_ref = borrow_global_mut<VaultRef>(DELTA_HEDGING);
            vault_ref.vault_address = new_vault_address;
            vault_ref.vault_extend_ref = extend_ref;
        };

        emit(CreateNewVault {
            new_vault_address: new_vault_address
        });
    }

    fun update_share_table(share_table: &mut Table<address, u64>, account: address, delta_share: u64, increase: bool) {
        let share = table::borrow_mut_with_default(share_table, account, 0);
        
        if (increase) {
            *share += delta_share;
        } else {
            assert!(*share >= delta_share, NOT_ENOUGH_SHARE);
            *share -= delta_share;
        };
    }

    fun update_fund_fee_table(share_table: &mut Table<address, I64>, account: address, value: u64, is_negative: bool) {
        let share = table::borrow_mut_with_default(share_table, account, init_i64(0, false));
        
        *share = init_i64(value, is_negative);
    }

    public entry fun deposit_risky_vault(signer: &signer, account: address, amount: u64, total_value: u64, value: u64, is_negative:bool) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let user_share: u64;
        let total_share = vault.total_share_of_risky_vault + vault.total_share_of_safety_vault;
        if( total_share == 0) {
            user_share = amount * 1_000_000;
        } else user_share = total_share * amount / total_value;

        update_share_table(&mut vault.users_share_in_risky_vault, account, user_share, true);
        update_share_table(&mut vault.users_amount_in_risky_vault, account, amount, true);
        // update_fund_fee_table(&mut vault.users_amount_fee_in_risky_vault, account, value_fee, is_negative);
        vault.total_value_lock += amount;
        vault.total_share_of_risky_vault += user_share;

        transfer_usdc(signer, vault_ref.vault_address, amount);

        emit(Deposited {
            account,
            amount,
            is_risky: true,
        });
    }

    public entry fun deposit_safety_vault(signer: &signer, account: address, amount: u64, total_value: u64, value: u64, is_negative:bool) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let user_share: u64;
        let total_share = vault.total_share_of_risky_vault + vault.total_share_of_safety_vault;
        if( total_share == 0) {
            user_share = amount * 1_000_000;
        } else user_share = total_share * amount / total_value;

        update_share_table(&mut vault.users_share_in_safety_vault, account, user_share, true);
        update_share_table(&mut vault.users_amount_in_safety_vault, account, amount, true);
        // update_fund_fee_table(&mut vault.users_amount_fee_in_safety_vault, account, value_fee, is_negative);

        vault.total_value_lock += amount;
        vault.total_share_of_safety_vault += user_share;

        transfer_usdc(signer, vault_ref.vault_address, amount);
        
        emit(Deposited {
            account,
            amount,
            is_risky: false,
        });
    }

    public entry fun open_position(_signer: &signer, collateral_delta: u64, leverage: u64) acquires Vault, VaultRef {
        // only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let pair = get_pair();
        simple_trade(vault_signer, vault_ref.vault_address, collateral_delta, leverage, true, pair);

        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        vault.total_perpeptual += collateral_delta;
        emit(OpenPerp {
            collateral_delta,
            leverage,
            pair
        });
    }

    public entry fun liquid_staking(_signer: &signer, amountUSDC: u64) acquires Vault, VaultRef {
        // only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let amountAPTMin = get_amounts_out_USDC_APT_cellana(amountUSDC);
        swap_USDC_to_APT(vault_signer, amountUSDC);
        // stake(vault_signer, amountAPTMin, vault_ref.vault_address);

        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        vault.total_staked += amountAPTMin;
        emit(Stake {
            amount: amountAPTMin
        })
    }
    
    public entry fun liquid_staking_APT(_signer: &signer, amountUSDC: u64, amountAPTMin: u64) acquires Vault, VaultRef {
        // only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        swap_USDC_to_APT(vault_signer, amountUSDC);

        stake(vault_signer, amountAPTMin, vault_ref.vault_address);

        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        vault.total_staked += amountAPTMin;
        emit(Stake {
            amount: amountAPTMin
        })
    }

    public entry fun withdraw_risky_vault(_signer: &signer, account: address, amount:u64, amountClose: u64, leverage: u64, amountUnstake:u64, total_value: u64) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let pair = get_pair();
        simple_trade(vault_signer, vault_ref.vault_address, amountClose, leverage, false, pair);
        
        let apt_unstake = get_amounts_out_USDC_APT_cellana(amountUnstake);
        unstake_amAPT(vault_signer, apt_unstake, vault_ref.vault_address);

        let amount_usdc_unstake = get_amounts_out_APT_USDC_cellana(apt_unstake);
        swap_amAPT_to_USDC(vault_signer, amount_usdc_unstake);
        
        // let fund_fee_risky = total_fund_fee_in_risky_vault();
        
        // transfer_usdc(vault_signer, account, amountClose);
        
        let total_share = vault.total_share_of_risky_vault + vault.total_share_of_safety_vault;
        let user_share = total_share * amount / total_value;

        // update_share_table(&mut vault.users_share_in_risky_vault, account, user_share, false);
        // update_share_table(&mut vault.users_amount_in_risky_vault, account, amount, false);
        vault.total_value_lock -= amount;
        vault.total_share_of_risky_vault -= user_share;

        emit(Withdrawn {
            account,
            amount,
            is_risky: true,
        });
    }

    public entry fun withdraw_safety_vault(_signer: &signer, account: address, amount:u64, amountClose: u64, leverage: u64, amountUnstake:u64, total_value: u64) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let pair = get_pair();

        simple_trade(vault_signer, vault_ref.vault_address, amountClose, leverage, false, pair);
        let apt_unstake = get_amounts_out_USDC_APT_cellana(amountUnstake);
        unstake_amAPT(vault_signer, apt_unstake, vault_ref.vault_address);

        let amount_usdc_unstake = get_amounts_out_APT_USDC_cellana(apt_unstake);
        swap_amAPT_to_USDC(vault_signer, amount_usdc_unstake);
        
        let total_share = vault.total_share_of_risky_vault + vault.total_share_of_safety_vault;
        let user_share = total_share * amount / total_value;

        update_share_table(&mut vault.users_share_in_safety_vault, account, user_share, false);
        update_share_table(&mut vault.users_amount_in_safety_vault, account, amount, false);
        vault.total_value_lock -= amount;
        vault.total_share_of_safety_vault -= user_share;
        
        transfer_usdc(vault_signer, account, amountClose);

        emit(Withdrawn {
            account,
            amount,
            is_risky: false,
        });
    }

   fun fund_fee_risky(value: u64, is_negative: bool): I64 acquires Vault, VaultRef {
        let fund_fee = init_i64(value, is_negative);
        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        // let fund_fee = borrow_global<Vault>(vault_address).fund_fee;
        let risky_rate_numerator = borrow_global<Vault>(vault_address).fund_fee_risky_rate_numerator;
        let risky_rate_denominator = borrow_global<Vault>(vault_address).fund_fee_risky_rate_denominator;
        let fund_fee_risky: I64;
        if( is_negative(fund_fee) ) {
            return init_i64(get_value(fund_fee), true);
        };
        fund_fee_risky = init_i64(get_value(fund_fee) * risky_rate_numerator / risky_rate_denominator, is_negative(fund_fee));

        fund_fee_risky
    }

    fun fund_fee_after_risky(value: u64, is_negative: bool): I64 acquires Vault, VaultRef {
        let fund_fee = init_i64(value, is_negative);
        // let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        // let fund_fee = borrow_global<Vault>(vault_address).fund_fee;
        let fund_fee_after_risky = fund_fee_risky(value, is_negative);

        sub(fund_fee, fund_fee_after_risky)
    }

    fun calc_fund_fee(
        _fund_fee: I64,
        _user_share: u64,
        _total_share: u64,
    ): I64 {
        let result: u64 = get_value(_fund_fee) * _user_share / _total_share;
        let is_negative: bool = false;

        init_i64(result, is_negative)
    }

    public fun total_fund_fee_in_risky_vault(value: u64, is_negative: bool): I64 acquires Vault, VaultRef {
        let fund_fee = init_i64(value, is_negative);
        let fund_fee_risky = fund_fee_risky(value, is_negative);
        let fund_fee_after_risky = fund_fee_after_risky(value, is_negative);

        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        // let fund_fee = borrow_global<Vault>(vault_address).fund_fee;

        let safety_vault = borrow_global<Vault>(vault_address).total_share_of_safety_vault;
        let risky_vault = borrow_global<Vault>(vault_address).total_share_of_risky_vault;

        if (is_negative(fund_fee)) {
            return init_i64(get_value(fund_fee_risky), true);
        };
        let result = get_value(fund_fee_risky) + get_value(fund_fee_after_risky) * risky_vault / (safety_vault + risky_vault);
        let is_negative = is_negative(fund_fee_risky);

        init_i64(result, is_negative)
    }

    public fun total_fund_fee_in_safety_vault(value: u64, is_negative: bool): u64 acquires Vault, VaultRef {
        let result: u64 = 0;
        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        let fund_fee = init_i64(value, is_negative);
        // let fund_fee = borrow_global<Vault>(vault_address).fund_fee;

        if (!is_negative(fund_fee)) {
            let safety_vault = borrow_global<Vault>(vault_address).total_share_of_safety_vault;
            let risky_vault = borrow_global<Vault>(vault_address).total_share_of_risky_vault;
            
            let fund_fee_after_risky = fund_fee_after_risky(value, is_negative);
            result = get_value(fund_fee_after_risky) * safety_vault / (safety_vault + risky_vault);
        };

        result
    }

    public entry fun set_fund_fee_risky_rate(signer: &signer, numerator: u64, denominator: u64) acquires Vault, VaultRef {
        only_admin(signer);
        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        let vault = borrow_global_mut<Vault>(vault_address);

        vault.fund_fee_risky_rate_numerator = numerator;
        vault.fund_fee_risky_rate_denominator = denominator;
    }

    public entry fun set_fund_fee(signer: &signer, value: u64, is_negative: bool) acquires Vault, VaultRef {
        only_admin(signer);
        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        let vault = borrow_global_mut<Vault>(vault_address);
        vault.fund_fee = init_i64(value, is_negative);
    }

    public entry fun redeem_usdc(signer: &signer, account:address, amount:u64) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        transfer_usdc(vault_signer, account, amount);
    }
}